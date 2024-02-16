import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

public final class VideoListViewModel: ObservableObject {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let syncModel: VideoRevampSyncModel
    private(set) var reloadVideosTask: Task<Void, Never>?
    
    @Published private(set) var videos = [NodeEntity]()
    @Published var searchedText = ""
    @Published private(set) var shouldShowError = false
    
    public init(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        syncModel: VideoRevampSyncModel
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.syncModel = syncModel
    }
    
    func onViewAppeared() async {
        do {
            try await loadVideos(sortOrderType: syncModel.videoRevampSortOrderType)
            try Task.checkCancellation()
            
            fileSearchUseCase.startNodesUpdateListener()
            listenNodesUpdate()
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
            try? await loadVideos(sortOrderType: sortOrderType)
        }
    }
    
    func onViewDissapeared() {
        reloadVideosTask?.cancel()
        reloadVideosTask = nil
        
        fileSearchUseCase.stopNodesUpdateListener()
    }
    
    @MainActor
    private func loadVideos(sortOrderType: SortOrderEntity? = .defaultAsc) async throws {
        do {
            videos = try await search(by: searchedText, sortOrderType: sortOrderType)
        } catch {
            throw error
        }
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
}
