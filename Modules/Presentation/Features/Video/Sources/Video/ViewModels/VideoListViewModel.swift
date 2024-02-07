import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift

public final class VideoListViewModel: ObservableObject {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private(set) var reloadVideosTask: Task<Void, Never>?
    
    @Published private(set) var videos = [NodeEntity]()
    @Published var searchedText = ""
    @Published var sortOrderType = SortOrderEntity.defaultAsc
    @Published private(set) var shouldShowError = false
    
    public init(fileSearchUseCase: some FilesSearchUseCaseProtocol, thumbnailUseCase: some ThumbnailUseCaseProtocol) {
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    func onViewAppeared() async {
        do {
            try await loadVideos()
            try Task.checkCancellation()
            
            fileSearchUseCase.startNodesUpdateListener()
            listenNodesUpdate()
        } catch {
            shouldShowError = true
        }
    }
    
    func onViewDissapeared() {
        reloadVideosTask?.cancel()
        reloadVideosTask = nil
        
        fileSearchUseCase.stopNodesUpdateListener()
    }
    
    @MainActor
    private func loadVideos() async throws {
        do {
            videos = try await search(by: searchedText)
        } catch {
            throw error
        }
    }
    
    private func search(by text: String) async throws -> [NodeEntity] {
        try await fileSearchUseCase.search(
            string: text,
            parent: nil,
            recursive: true,
            supportCancel: false,
            sortOrderType: sortOrderType,
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
                try await loadVideos()
            } catch {
                shouldShowError = true
            }
        }
    }
}
