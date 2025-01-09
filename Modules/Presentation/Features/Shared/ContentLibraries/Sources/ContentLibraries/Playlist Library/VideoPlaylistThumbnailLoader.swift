import MEGADomain
import MEGAPresentation

public protocol VideoPlaylistThumbnailLoaderProtocol: Sendable {
    func loadThumbnails(for videos: [NodeEntity]) async -> VideoPlaylistThumbnail
}

public struct VideoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoaderProtocol {
    
    private let maxThumbnailToBeDisplayedCount = 4
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let fallbackImageContainer: (any ImageContaining)
    private typealias TaskGroupThumbnails = TaskGroup<(order: Int, imageContainer: (any ImageContaining)?)>
    
    public init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        fallbackImageContainer: some ImageContaining
    ) {
        self.thumbnailLoader = thumbnailLoader
        self.fallbackImageContainer = fallbackImageContainer
    }
    
    public func loadThumbnails(for videos: [NodeEntity]) async -> VideoPlaylistThumbnail {
        if videos.isEmpty {
            return VideoPlaylistThumbnail(type: .empty, imageContainers: [])
        }
        
        if videos.allSatisfy({ !$0.hasThumbnail }) {
            return VideoPlaylistThumbnail(type: .allVideosHasNoThumbnails, imageContainers: [fallbackImageContainer])
        }
        
        return await withTaskGroup(of: TaskGroupThumbnails.Element.self) { taskGroup -> VideoPlaylistThumbnail in
            let onlyHasThumbailVideos = videos.filter(\.hasThumbnail)
            let thumbnailToBeDisplayed = min(maxThumbnailToBeDisplayedCount, onlyHasThumbailVideos.count)
            var iterator = onlyHasThumbailVideos.enumerated().makeIterator()
            let loadNext = { ( taskGroup: inout TaskGroupThumbnails) -> Bool in
                guard let (order, video) = iterator.next() else {
                    return false
                }
                _ = taskGroup.addTaskUnlessCancelled {
                    let container = try? await thumbnailLoader.loadImage(for: video, type: .thumbnail)
                    return (order, imageContainer: container)
                }
                
                return true
            }

            for _ in 0..<thumbnailToBeDisplayed {
                guard loadNext(&taskGroup) else { break }
            }
            
            var results: [(order: Int, imageContainer: (any ImageContaining))] = []
            for await result in taskGroup {
                if let imageContainer = result.imageContainer {
                    results.append((result.order, imageContainer))
                } else if !loadNext(&taskGroup), taskGroup.isEmpty {
                    break
                }
                
                if results.count == thumbnailToBeDisplayed {
                    break
                }
            }
            
            taskGroup.cancelAll()
            
            let imageContainers = results.sorted { a, b in a.order < b.order }
                .map(\.imageContainer)
            
            return VideoPlaylistThumbnail(type: .normal, imageContainers: imageContainers)
        }
    }
}
