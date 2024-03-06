import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

public final class VideoListViewModel: ObservableObject {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private(set) var syncModel: VideoRevampSyncModel
    private(set) var reloadVideosTask: Task<Void, Never>?
    
    private(set) var selection = VideoSelection()
    private var subscriptions = Set<AnyCancellable>()
    
    @Published private(set) var videos = [NodeEntity]()
    @Published private(set) var shouldShowError = false
    
    public init(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        syncModel: VideoRevampSyncModel
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.syncModel = syncModel
        
        subscribeToEditingMode()
        subscribeToAllSelected()
    }
    
    func onViewAppeared() async {
        do {
            try await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
            try Task.checkCancellation()
            
            fileSearchUseCase.startNodesUpdateListener()
            listenNodesUpdate()
        } catch is CancellationError {
            // Better to log the cancellation in future MR. Currently MEGALogger is from main module.
        } catch {
            shouldShowError = true
        }
    }
    
    func monitorSortOrderChanged() async {
        let sortOrderAsyncSequence = syncModel.$videoRevampSortOrderType
            .removeDuplicates()
            .dropFirst()
            .values
        
        for await sortOrderType in sortOrderAsyncSequence {
            try? await loadVideos(searchText: syncModel.searchText, sortOrderType: sortOrderType)
        }
    }
    
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
    
    func onViewDissapeared() {
        reloadVideosTask?.cancel()
        reloadVideosTask = nil
        
        fileSearchUseCase.stopNodesUpdateListener()
    }
    
    func toggleSelectAllVideos() {
        let allSelectedCurrently = selection.videos.count == videos.count
        selection.allSelected = !allSelectedCurrently
        
        if selection.allSelected {
            selection.setSelectedVideos(videos)
        }
    }
    
    @MainActor
    private func loadVideos(searchText: String = "", sortOrderType: SortOrderEntity? = .defaultAsc) async throws {
        try Task.checkCancellation()
        videos = try await search(by: searchText, sortOrderType: sortOrderType)
    }
    
    private func search(by text: String, sortOrderType: SortOrderEntity?) async throws -> [NodeEntity] {
        try await fileSearchUseCase.search(
            string: text,
            parent: nil,
            recursive: true,
            supportCancel: false,
            sortOrderType: sortOrderType ?? .defaultAsc,
            formatType: .video,
            cancelPreviousSearchIfNeeded: true
        )
    }
    
    private func listenNodesUpdate() {
        fileSearchUseCase.onNodesUpdate { [weak self] nodes in
            self?.update(nodes)
        }
    }
    
    private func update(_ nodes: [NodeEntity]) {
        let updatedVideos = nodes.filter { $0.mediaType == .video }
        guard updatedVideos.isNotEmpty else { return }
        updateVideos(with: updatedVideos)
    }
    
    private func updateVideos(with updatedVideos: [NodeEntity]) {
        reloadVideosTask = Task {
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
    }
    
    private func subscribeToAllSelected() {
        syncModel.$isAllSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.selection.allSelected = $0
                self?.toggleSelectAllVideos()
            }
            .store(in: &subscriptions)
    }
}
