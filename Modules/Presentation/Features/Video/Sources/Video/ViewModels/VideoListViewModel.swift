import AsyncAlgorithms
import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

final class VideoListViewModel: ObservableObject {
    
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
    
    private(set) var syncModel: VideoRevampSyncModel
    private(set) var selection: VideoSelection
    
    @Published private(set) var videos = [NodeEntity]()
    @Published private(set) var chips: [ChipContainerViewModel] = [ FilterChipType.location, .duration ]
        .map { ChipContainerViewModel(title: $0.description, type: $0, isActive: false) }
    
    @Published private(set) var shouldShowFilterChip = true
    @Published private(set) var viewState: ViewState = .partial

    var actionSheetTitle: String {
        newlySelectedChip?.type.description ?? ""
    }
    
    @Published var isSheetPresented = false
    @Published var selectedLocationFilterOption: String = LocationChipFilterOptionType.allLocation.stringValue
    @Published var selectedDurationFilterOption: String = DurationChipFilterOptionType.allDurations.stringValue
    var newlySelectedChip: ChipContainerViewModel?

    private var selectedLocationFilterOptionType: LocationChipFilterOptionType { .init(rawValue: selectedLocationFilterOption) ?? .allLocation }
    private var selectedDurationFilterOptionType: DurationChipFilterOptionType { .init(rawValue: selectedDurationFilterOption) ?? .allDurations }
    private let contentProvider: any VideoListViewModelContentProviderProtocol
    private let monitorSearchRequestsSubject = CurrentValueSubject<MonitorSearchRequest, Never>(.invalidate)
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()

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
    
    init(
        syncModel: VideoRevampSyncModel,
        contentProvider: some VideoListViewModelContentProviderProtocol,
        selection: VideoSelection,
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.syncModel = syncModel
        self.selection = selection
        
        self.contentProvider = contentProvider
        
        subscribeToEditingMode()
        subscribeToAllSelected()
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
        
        // Observe Location Filter Changes
        let locationFilter = $selectedLocationFilterOption
            .map { LocationChipFilterOptionType(rawValue: $0) ?? .allLocation }
            .removeDuplicates()

        // Observe Duration Filter Changes
        let durationFilter = $selectedDurationFilterOption
            .map { DurationChipFilterOptionType(rawValue: $0) ?? .allDurations }
            .removeDuplicates()
        
        let queryParamSequence = searchText.combineLatest(sortOrder, locationFilter, durationFilter)
            
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
    private func performSearch(searchText: String = "", sortOrderType: SortOrderEntity, selectedLocationFilterOptionType: LocationChipFilterOptionType, selectedDurationFilterOptionType: DurationChipFilterOptionType) {
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
            selection.setSelectedVideos(videos)
        }
    }
    
    func didFinishSelectFilterOption(_ selectedChip: ChipContainerViewModel) {
        toggleChip(selectedChip)
    }
    
    @MainActor
    private func loadVideos(searchText: String = "", sortOrderType: SortOrderEntity = .defaultAsc, selectedLocationFilterOptionType: LocationChipFilterOptionType, selectedDurationFilterOptionType: DurationChipFilterOptionType) async throws {
        try Task.checkCancellation()
        self.videos = try await contentProvider
            .search(by: searchText, sortOrderType: sortOrderType, durationFilterOptionType: selectedDurationFilterOptionType, locationFilterOptionType: selectedLocationFilterOptionType)
    }
    
    private func subscribeToEditingMode() {
        syncModel.$editMode
            .receive(on: DispatchQueue.main)
            .assign(to: &selection.$editMode)
        
        selection.$editMode
            .map { !$0.isEditing }
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowFilterChip)
    }
    
    private func subscribeToAllSelected() {
        syncModel.$isAllSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.toggleSelectAllVideos()
            }
            .store(in: &subscriptions)
    }
    
    private func toggleChip(_ selectedChip: ChipContainerViewModel) {
        for (index, chip) in chips.enumerated() where chip.title == selectedChip.title {
            chips[index] = ChipContainerViewModel(title: title(for: chip), type: chip.type, isActive: shouldActivate(chip: chip))
        }
    }
    
    private func shouldActivate(chip: ChipContainerViewModel) -> Bool {
        switch chip.type {
        case .location:
            selectedLocationFilterOptionType != .allLocation
        case .duration:
            selectedDurationFilterOptionType != .allDurations
        }
    }
    
    private func title(for chip: ChipContainerViewModel) -> String {
        switch chip.type {
        case .location:
            if selectedLocationFilterOptionType == .allLocation {
                return chip.type.description
            } else {
                return selectedLocationFilterOption
            }
        case .duration:
            if selectedDurationFilterOptionType == .allDurations {
                return chip.type.description
            } else {
                return selectedDurationFilterOption
            }
        }
    }
    
    private func subscribeToChipFilterOptions() {
        
        let selectedDurationFilterOptionChangePublisher = $selectedDurationFilterOption.dropFirst()
        let selectedLocationFilterOptionChangePublisher = $selectedLocationFilterOption.dropFirst()
        
        selectedDurationFilterOptionChangePublisher
            .merge(with: selectedLocationFilterOptionChangePublisher)
            .removeDuplicates()
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
