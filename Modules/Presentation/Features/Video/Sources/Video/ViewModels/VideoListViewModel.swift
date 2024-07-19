import AsyncAlgorithms
import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

public final class VideoListViewModel: ObservableObject {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
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
    @Published private(set) var shouldShowError = false
    
    @Published private(set) var chips: [ChipContainerViewModel] = [ FilterChipType.location, .duration ]
        .map { ChipContainerViewModel(title: $0.description, type: $0, isActive: false) }
    
    @Published private(set) var shouldShowFilterChip = true
    
    @Published private(set) var shouldShowPlaceHolderView = false
    @Published private(set) var shouldShowVideosEmptyView = false
    
    var actionSheetTitle: String {
        newlySelectedChip?.type.description ?? ""
    }
    
    @Published var isSheetPresented = false
    @Published var selectedLocationFilterOption: String = LocationChipFilterOptionType.allLocation.stringValue
    @Published var selectedDurationFilterOption: String = DurationChipFilterOptionType.allDurations.stringValue
    
    private(set) var selectedLocationFilterOptionType: LocationChipFilterOptionType = .allLocation
    private(set) var selectedDurationFilterOptionType: DurationChipFilterOptionType = .allDurations
    
    var newlySelectedChip: ChipContainerViewModel?
    
    public init(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        syncModel: VideoRevampSyncModel,
        selection: VideoSelection
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.syncModel = syncModel
        self.selection = selection
        
        subscribeToEditingMode()
        subscribeToAllSelected()
        subscribeToChipFilterOptions()
        subscribeToItemsStateForEmptyState()
        monitorSortOrderChanged()
    }
    
    @MainActor
    func onViewAppear() async {
        do {
            shouldShowPlaceHolderView = videos.isEmpty
            try await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
            try Task.checkCancellation()
        } catch is CancellationError {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
        } catch {
            shouldShowError = true
        }
        shouldShowPlaceHolderView = false
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
                shouldShowError = true
            }
        }
    }
    
    func listenNodesUpdate() async {
        for await nodes in fileSearchUseCase.nodeUpdates {
            update(nodes)
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
        self.videos = try await search(by: searchText, sortOrderType: sortOrderType)
    }
    
    private func search(by searchText: String = "", sortOrderType: SortOrderEntity?) async throws -> [NodeEntity] {
        let filteredLocationVideos = try await videos(by: searchText, sortOrderType: sortOrderType)
        try Task.checkCancellation()
        return videosFiltered(by: selectedDurationFilterOptionType, videos: filteredLocationVideos)
    }
    
    private func videos(by searchText: String = "", sortOrderType: SortOrderEntity?) async throws -> [NodeEntity] {
        let filteredLocationVideos = try await photoLibraryUseCase.media(
            for: filterOptionEntity(for: selectedLocationFilterOptionType),
            excludeSensitive: nil,
            searchText: searchText,
            sortOrder: sortOrderType ?? .defaultAsc
        )
        
        return switch selectedLocationFilterOptionType {
        case .sharedItems: 
            filteredLocationVideos.filter(\.isExported)
        default: 
            filteredLocationVideos
        }
    }
    
    private func filterOptionEntity(for locationType: LocationChipFilterOptionType?) -> PhotosFilterOptionsEntity {
        switch locationType {
        case .allLocation, .sharedItems, .none:
            [ .videos, .allLocations ]
        case .cloudDrive:
            [ .videos, .cloudDrive ]
        case .cameraUploads:
            [ .videos, .cameraUploads ]
        }
    }
    
    private func videosFiltered(by durationType: DurationChipFilterOptionType?, videos: [NodeEntity]) -> [NodeEntity] {
        guard let durationFilter = videoFilter(for: durationType) else {
            return videos
        }
        return videos.filter(durationFilter)
    }
    
    private func videoFilter(for durationType: DurationChipFilterOptionType?) -> ((NodeEntity) -> Bool)? {
        switch durationType {
        case .lessThan10Seconds:
            return { $0.duration < 10 }
        case .between10And60Seconds:
            return { $0.duration >= 10 && $0.duration < 60 }
        case .between1And4Minutes:
            return { $0.duration >= 60 && $0.duration < 240 }
        case .between4And20Minutes:
            return { $0.duration >= 240 && $0.duration < 1200 }
        case .moreThan20Minutes:
            return { $0.duration >= 1200 }
        default:
            return nil
        }
    }
    
    private func update(_ nodes: [NodeEntity]) {
        guard nodes.contains(where: { $0.mediaType == .video }) else { return }
        let updatedVideos = nodes.filter { $0.mediaType == .video }
        updateVideos(with: updatedVideos)
    }
    
    private func updateVideos(with updatedVideos: [NodeEntity]) {
        reloadVideosTask = Task { @MainActor in
            do {
                try await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
            } catch {
                shouldShowError = true
            }
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
        reloadfilteredVideosTask = Task {
            try? Task.checkCancellation()
            try? await self.loadVideos(sortOrderType: self.syncModel.videoRevampSortOrderType)
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
    
    private func subscribeToItemsStateForEmptyState() {
        let videosStream = $videos.map(\.isEmpty).dropFirst().removeDuplicates()
        let isLoadingStream = $shouldShowPlaceHolderView.dropFirst().removeDuplicates()
        
        Publishers.CombineLatest(videosStream, isLoadingStream)
            .map { $0 && !$1 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowVideosEmptyView)
    }
}
