import AsyncAlgorithms
import Combine
import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGASwiftUI
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
    
    @Published private(set) var showSortHeader = true
    @Published private(set) var viewState: ViewState = .partial
    @Published var emptyViewModel: ContentUnavailableViewModel?

    var actionSheetTitle: String {
        newlySelectedChip?.type.description ?? ""
    }
    
    @Published var isSheetPresented = false
    @Published public var selectedLocationFilterOption: LocationChipFilterOptionType = .allLocation
    @Published public var selectedDurationFilterOption: DurationChipFilterOptionType = .allDurations
    @Published private(set) var sortOrder: MEGAUIComponent.SortOrder
    var newlySelectedChip: ChipContainerViewModel?

    private let contentProvider: any VideoListViewModelContentProviderProtocol
    private let monitorSearchRequestsSubject = CurrentValueSubject<MonitorSearchRequest, Never>(.invalidate)
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let sortOptions: [SortOption]
    let sortHeaderConfig: SortHeaderConfig
    
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
    
    public init(
        syncModel: VideoRevampSyncModel,
        contentProvider: some VideoListViewModelContentProviderProtocol,
        selection: VideoSelection,
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
        self.syncModel = syncModel
        self.selection = selection

        self.contentProvider = contentProvider

        let sortOptions = VideoSortOptionsFactory.makeAll()
        self.sortOptions = sortOptions
        self.sortHeaderConfig = SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: sortOptions
        )

        // Read the stored preference synchronously so the very first search already runs in the saved order
        let storedSortOrder = Self.supportedSortOrder(
            sortOrderPreferenceUseCase.sortOrder(for: .homeVideos).toUIComponentSortOrderEntity(),
            in: sortOptions)
        self.sortOrder = storedSortOrder

        monitorSortOrderPreference()
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
        // Observe Sort Order Changes. Sourced from our own normalised `sortOrder` rather than the
        // shared `syncModel`: the host screen writes the raw stored order there (which can be an
        // order this list can't display), so following it would query in an order the sort header
        // doesn't show.
        let sortOrder = $sortOrder
            .map { $0.toDomainSortOrderEntity() }
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
                updateEmptyViewModel()
            } catch is CancellationError {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            } catch {
                viewState = videos.isEmpty ? .error : .loaded
                updateEmptyViewModel()
            }
        }
    }
        
    private func updateEmptyViewModel() {
        guard viewState == .empty || viewState == .error else {
            emptyViewModel = nil
            return
        }

        emptyViewModel = ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassVideo,
            title: Strings.Localizable.Videos.Tab.All.Content.emptyState,
            subtitle: nil,
            font: .body,
            titleTextColor: TokenColors.Text.primary.swiftUI,
            actions: []
        )
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
    
    /// The user picked an order in the sort header — the only path that writes it to storage.
    func didSelectSortOrder(_ newSortOrder: MEGAUIComponent.SortOrder) {
        guard applySortOrder(newSortOrder) else { return }
        sortOrderPreferenceUseCase.save(sortOrder: newSortOrder.toDomainSortOrderEntity(), for: .homeVideos)
    }

    /// Keeps the sort header in step with the stored preference: it emits the saved order on
    /// subscription and again whenever it changes elsewhere — which happens when the user's sorting
    /// basis is "same for all" and another screen changes the sort.
    ///
    /// Deliberately does not save: the incoming order is only coerced for display, and writing that
    /// coerced value back would overwrite the order the user actually chose on the other screen.
    private func monitorSortOrderPreference() {
        sortOrderPreferenceUseCase
            .monitorSortOrder(for: .homeVideos)
            .receive(on: DispatchQueue.main)
            .map { [sortOptions] in
                Self.supportedSortOrder($0.toUIComponentSortOrderEntity(), in: sortOptions)
            }
            .removeDuplicates()
            .sink { [weak self] order in
                self?.applySortOrder(order)
            }
            .store(in: &subscriptions)
    }

    /// Applies `newSortOrder` to the header and the search query, returning whether it actually moved.
    ///
    /// Only ``sortOrder`` is written: `syncModel.videoRevampSortOrderType` is owned by the host screen
    /// (the legacy tab container keeps its context menu in sync with the raw stored order there), and
    /// a second writer publishing this normalised value would fight it.
    @discardableResult
    private func applySortOrder(_ newSortOrder: MEGAUIComponent.SortOrder) -> Bool {
        guard sortOrder != newSortOrder else { return false }
        sortOrder = newSortOrder
        return true
    }

    /// The stored preference can hold an order the video sort header doesn't offer — a "same for all"
    /// order set by another screen (date added, for instance). Anything unsupported shows, and sorts,
    /// as the default name order, matching what the header is able to display.
    ///
    /// `SortOption.id` is its sort key.
    private nonisolated static func supportedSortOrder(
        _ sortOrder: MEGAUIComponent.SortOrder,
        in options: [SortOption]
    ) -> MEGAUIComponent.SortOrder {
        options.contains { $0.id == sortOrder.key } ? sortOrder : MEGAUIComponent.SortOrder(key: .name)
    }
    
    private func subscribeToEditingMode() {
        syncModel.$editMode
            .receive(on: DispatchQueue.main)
            .assign(to: &selection.$editMode)

        selection.$editMode
            .map { editMode in
                return !editMode.isEditing
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$showSortHeader)
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
