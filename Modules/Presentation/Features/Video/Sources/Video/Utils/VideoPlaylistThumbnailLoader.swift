import MEGADomain
import MEGAPresentation

protocol VideoPlaylistThumbnailLoaderProtocol {
    func loadThumbnails(for videos: [NodeEntity]) async -> [(any ImageContaining)]
}

struct VideoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoaderProtocol {
    
    let thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    private let maxThumbnailToBeDisplayedCount = 4
    
    func loadThumbnails(for videos: [NodeEntity]) async -> [(any ImageContaining)] {
        await withTaskGroup(of: (order: Int, imageContainer: (any ImageContaining)?).self) { group -> [(any ImageContaining)] in
            for (index, video) in videos.prefix(maxThumbnailToBeDisplayedCount).enumerated() where video.hasThumbnail {
                group.addTask {
                    let container = try? await thumbnailUseCase.loadThumbnailContainer(for: video, type: .thumbnail)
                    return (order: index, imageContainer: container)
                }
            }
            
            return await group
                .reduce(into: Array(repeating: Optional<any ImageContaining>.none, count: maxThumbnailToBeDisplayedCount)) { $0[$1.0] = $1.1 }
                .compactMap { $0 }
        }
    }
}
