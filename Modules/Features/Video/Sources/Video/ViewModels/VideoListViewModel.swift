import AsyncAlgorithms
import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGAUIComponent

@MainActor
public final class VideoListViewModel: ObservableObject {
    
    enum ViewState: Equatable {
        case partial
        case loading
        case loaded
        case empty
        case error
    }
    
    enum MonitorSearchRequest {
        /// Request invalidate results and perform search request immediately
        case invalidate
        /// Reinitialise results and perform search request when a change has occurred since before
        case reinitialise
    }
    
    let thumbnailLoader: any ThumbnailLoaderProtocol
    let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    let nodeUseCase: any NodeUseCaseProtocol
    let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private(set) var syncModel: VideoRevampSyncModel
    private(set) var selection: VideoSelection
    
    @Published private(set) var videos = [NodeEntity]()
    @Published private(set) var chips: [ChipContainerViewModel] = [ FilterChipType.location, .duration ]
        .map { ChipContainerViewModel(title: $0.description, type: $0, isActive: false) }
    
    var mediaRevampEnabled = true
    @Published private(set) var showFilterChips = true
    @Published private(set) var showSortHeader = true
    @Published private(set) var viewState: ViewState = .partial

    var actionSheetTitle: String {
        newlySelectedChip?.type.description ?? ""
    }
    
    @Published var isSheetPresented = false
    @Published public var selectedLocationFilterOption: LocationChipFilterOptionType = .allLocation
    @Published public var selectedDurationFilterOption: DurationChipFilterOptionType = .allDurations
    var newlySelectedChip: ChipContainerViewModel?

    private let contentProvider: any VideoListViewModelContentProviderProtocol
    private let monitorSearchRequestsSubject = CurrentValueSubject<MonitorSearchRequest, Never>(.invalidate)
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let sortHeaderCoordinator: SortHeaderCoordinator

    private var subscriptions = Set<AnyCancellable>()

    var sortHeaderViewModel: SortHeaderViewModel {
        sortHeaderCoordinator.headerViewModel
    }

    private var searchTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    private var monitorNodeUpdatesTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    deinit {
        searchTask = nil
        monitorNodeUpdatesTask = nil
    }
    
    public init(
        syncModel: VideoRevampSyncModel,
        contentProvider: some VideoListViewModelContentProviderProtocol,
        selection: VideoSelection,
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
        self.syncModel = syncModel
        self.selection = selection

        self.mediaRevampEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
        self.showFilterChips = !mediaRevampEnabled
        self.showSortHeader = mediaRevampEnabled

        self.contentProvider = contentProvider

        self.sortHeaderCoordinator = .init(
            sortOptionsViewModel: .init(
                title: Strings.Localizable.sortTitle,
                sortOptions: VideoSortOptionsFactory.makeAll()
            ),
            currentSortOrderProvider: { [weak syncModel] in
                (syncModel?.videoRevampSortOrderType ?? .defaultAsc).toUIComponentSortOrderEntity()
            },
            sortOptionSelectionHandler: { @MainActor [weak syncModel] sortOption in
                syncModel?.videoRevampSortOrderType = sortOption.sortOrder.toDomainSortOrderEntity()
            }
        )

        subscribeToEditingMode()
        subscribeToAllSelected()
        subscribeToSelectedVideos()
        subscribeToChipFilterOptions()

        monitorNodeUpdatesTask = Task { @MainActor in await monitorNodeUpdates() }
    }
    
    @MainActor
    func onViewAppear() async {
        await monitorSearchChanges()
    }
    
    func onViewDisappear() {
        monitorSearchRequestsSubject.send(.reinitialise)
    }
            
    @MainActor
    private func monitorSearchChanges() async {
        // Observe Sort Order Changes
        let sortOrder = syncModel.$videoRevampSortOrderType
            .map { $0 ?? .defaultAsc }
            .removeDuplicates()
        
        // Observe Search Text Changes
        let scheduler = DispatchQueue(label: "VideoListSearchMonitor", qos: .userInteractive)
        let searchText = syncModel.$searchText
            .removeDuplicates()
            .debounceImmediate(for: .milliseconds(500), scheduler: scheduler)

        let emptySearchText = syncModel.$searchText
            .removeDuplicates()
            .filter { $0.isEmpty }
        // combine emptySearchText to send empty searchText immediately in case it's dropped by monitorSearchRequest.reinitialise
        let combinedSearchText = searchText.merge(with: emptySearchText).removeDuplicates()
        
        // Observe Location Filter Changes
        let locationFilter = $selectedLocationFilterOption
            .removeDuplicates()

        // Observe Duration Filter Changes
        let durationFilter = $selectedDurationFilterOption
            .removeDuplicates()
        
        let queryParamSequence = combinedSearchText.combineLatest(sortOrder, locationFilter, durationFilter)
            
        let asyncSequence = monitorSearchRequestsSubject
            .compactMap { monitorSearchRequest in
                switch monitorSearchRequest {
                case .invalidate:
                    queryParamSequence
                        .eraseToAnyPublisher()
                case .reinitialise:
                    queryParamSequence
                        .dropFirst()
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .values
        
        for await (searchText, sortOrder, locationFilter, durationFilter) in asyncSequence {
            performSearch(searchText: searchText, sortOrderType: sortOrder, selectedLocationFilterOptionType: locationFilter, selectedDurationFilterOptionType: durationFilter)
        }
    }
    
    @MainActor
    private func monitorNodeUpdates() async {
        for await _ in fileSearchUseCase.nodeUpdates.filter({ nodes in nodes.contains(where: \.name.fileExtensionGroup.isVideo) }) {
            monitorSearchRequestsSubject.send(.invalidate)
        }
    }
    
    @MainActor
    private func performSearch(searchText: String = "", sortOrderType: MEGADomain.SortOrderEntity, selectedLocationFilterOptionType: LocationChipFilterOptionType, selectedDurationFilterOptionType: DurationChipFilterOptionType) {
        if viewState == .partial {
            viewState = .loading
        }
        
        searchTask = Task {
            do {
                try await loadVideos(searchText: searchText,
                                     sortOrderType: sortOrderType,
                                     selectedLocationFilterOptionType: selectedLocationFilterOptionType,
                                     selectedDurationFilterOptionType: selectedDurationFilterOptionType)
                
                try Task.checkCancellation()
                
                viewState = videos.isNotEmpty ? .loaded : .empty
            } catch is CancellationError {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            } catch {
                viewState = videos.isEmpty ? .error : .loaded
            }
        }
    }
        
    func toggleSelectAllVideos() {
        let allSelectedCurrently = selection.videos.count == videos.count
        selection.allSelected = !allSelectedCurrently
        
        if selection.allSelected {
            setSelectedVideos(videos)
        }
    }
    
    func didFinishSelectFilterOption(_ selectedChip: ChipContainerViewModel) {
        toggleChip(selectedChip)
    }
    
    @MainActor
    private func loadVideos(searchText: String = "", sortOrderType: MEGADomain.SortOrderEntity = .defaultAsc, selectedLocationFilterOptionType: LocationChipFilterOptionType, selectedDurationFilterOptionType: DurationChipFilterOptionType) async throws {
        try Task.checkCancellation()
        self.videos = try await contentProvider
            .search(by: searchText, sortOrderType: sortOrderType, durationFilterOptionType: selectedDurationFilterOptionType, locationFilterOptionType: selectedLocationFilterOptionType)
    }
    
    private func subscribeToEditingMode() {
        syncModel.$editMode
            .receive(on: DispatchQueue.main)
            .assign(to: &selection.$editMode)

        if !mediaRevampEnabled {
            selection.$editMode
                .map { editMode in
                    return !editMode.isEditing
                }
                .receive(on: DispatchQueue.main)
                .assign(to: &$showFilterChips)
        } else {
            selection.$editMode
                .map { editMode in
                    return !editMode.isEditing
                }
                .receive(on: DispatchQueue.main)
                .assign(to: &$showSortHeader)
        }
    }
    
    private func subscribeToAllSelected() {
        syncModel.$isAllSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.toggleSelectAllVideos()
            }
            .store(in: &subscriptions)
    }

    private func subscribeToSelectedVideos() {
        syncModel.$selectedVideos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedVideos in
                guard let self else { return }
                guard let selectedVideos else {
                    return setSelectedVideos([])
                }
                setSelectedVideos(selectedVideos)
            }
            .store(in: &subscriptions)
    }

    private func setSelectedVideos(_ videos: [NodeEntity]) {
        selection.setSelectedVideos(videos)
    }

    private func toggleChip(_ selectedChip: ChipContainerViewModel) {
        for (index, chip) in chips.enumerated() where chip.title == selectedChip.title {
            chips[index] = ChipContainerViewModel(title: title(for: chip), type: chip.type, isActive: shouldActivate(chip: chip))
        }
    }
    
    private func shouldActivate(chip: ChipContainerViewModel) -> Bool {
        switch chip.type {
        case .location:
            selectedLocationFilterOption != .allLocation
        case .duration:
            selectedDurationFilterOption != .allDurations
        }
    }

    private func title(for chip: ChipContainerViewModel) -> String {
        switch chip.type {
        case .location:
            if selectedLocationFilterOption == .allLocation {
                return chip.type.description
            } else {
                return selectedLocationFilterOption.stringValue
            }
        case .duration:
            if selectedDurationFilterOption == .allDurations {
                return chip.type.description
            } else {
                return selectedDurationFilterOption.stringValue
            }
        }
    }
    
    private func subscribeToChipFilterOptions() {

        let selectedDurationFilterOptionChangePublisher = $selectedDurationFilterOption.dropFirst().map { _ in () }
        let selectedLocationFilterOptionChangePublisher = $selectedLocationFilterOption.dropFirst().map { _ in () }

        selectedDurationFilterOptionChangePublisher
            .merge(with: selectedLocationFilterOptionChangePublisher)
            .map { _ in false } // Trigger auto dismissal of sheet, on filter change
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSheetPresented)
    }
    
    var filterOptions: [String] {
        guard let type = newlySelectedChip?.type else {
            return []
        }
        
        switch type {
        case .location:
            return LocationChipFilterOptionType.allCases.map(\.stringValue)
        case .duration:
            return DurationChipFilterOptionType.allCases.map(\.stringValue)
        }
    }
}
