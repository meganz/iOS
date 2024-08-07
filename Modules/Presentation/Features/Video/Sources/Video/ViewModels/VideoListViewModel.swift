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
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    let thumbnailLoader: any ThumbnailLoaderProtocol
    let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    private(set) var syncModel: VideoRevampSyncModel
    private(set) var reloadVideosOnSortOrderChangedTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var reloadVideosTask: Task<Void, Never>?
    private(set) var reloadfilteredVideosTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    private(set) var selection: VideoSelection
    private var subscriptions = Set<AnyCancellable>()
    
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
    
    private(set) var selectedLocationFilterOptionType: LocationChipFilterOptionType = .allLocation
    private(set) var selectedDurationFilterOptionType: DurationChipFilterOptionType = .allDurations
    private let contentProvider: any VideoListViewModelContentProviderProtocol

    var newlySelectedChip: ChipContainerViewModel?
    init(
        syncModel: VideoRevampSyncModel,
        contentProvider: some VideoListViewModelContentProviderProtocol,
        selection: VideoSelection,
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.syncModel = syncModel
        self.selection = selection
        
        self.contentProvider = contentProvider
        
        subscribeToEditingMode()
        subscribeToAllSelected()
        subscribeToChipFilterOptions()
        monitorSortOrderChanged()
    }
    
    @MainActor
    func onViewAppear() async {
        do {
            if viewState == .partial {
                viewState = .loading
            }
            try await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
            try Task.checkCancellation()
        } catch is CancellationError {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
        } catch {
            viewState = videos.isEmpty ? .error : .loaded
        }
    }
    
    private func monitorSortOrderChanged() {
        syncModel.$videoRevampSortOrderType
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] sortOrderType in
                guard let self else {
                    return
                }
                reloadVideosOnSortOrderChangedTask = Task { @MainActor in
                    try? await self.loadVideos(searchText: self.syncModel.searchText, sortOrderType: sortOrderType)
                }
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func listenSearchTextChange() async {
        let sequence = syncModel
            .$searchText
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .compactMap { $0 }
            .values
        
        for await value in sequence {
            do {
                try Task.checkCancellation()
                try await loadVideos(searchText: value, sortOrderType: syncModel.videoRevampSortOrderType)
            } catch is CancellationError {
                break
            } catch {
                // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
            }
        }
    }
    
    @MainActor
    func listenNodesUpdate() async {
        for await _ in fileSearchUseCase
            .nodeUpdates
            .filter({ nodes in nodes.contains { $0.mediaType == .video } }) {
            await updateVideos()
        }
    }
    
    func onViewDissapeared() {
        reloadVideosTask?.cancel()
        reloadVideosTask = nil
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
    private func loadVideos(searchText: String = "", sortOrderType: SortOrderEntity? = .defaultAsc) async throws {
        try Task.checkCancellation()
        self.videos = try await contentProvider.search(by: searchText, sortOrderType: sortOrderType, durationFilterOptionType: selectedDurationFilterOptionType, locationFilterOptionType: selectedLocationFilterOptionType)
        viewState = videos.isNotEmpty ? .loaded : .empty
    }
    
    @MainActor
    private func updateVideos() async {
        do {
            try await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
        } catch {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
        }
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
        $selectedLocationFilterOption
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rawValue in
                guard let self else {
                    return
                }
                selectedLocationFilterOptionType = LocationChipFilterOptionType(rawValue: rawValue) ?? .allLocation
                reloadVideosInTask()
                isSheetPresented = false
            }
            .store(in: &subscriptions)
        
        $selectedDurationFilterOption
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rawValue in
                guard let self else {
                    return
                }
                selectedDurationFilterOptionType = DurationChipFilterOptionType(rawValue: rawValue) ?? .allDurations
                reloadVideosInTask()
                isSheetPresented = false
            }
            .store(in: &subscriptions)
    }
    
    private func reloadVideosInTask() {
        reloadfilteredVideosTask = Task { @MainActor [weak self]  in
            guard let self else { return }
            try? Task.checkCancellation()
            try? await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
        }
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
