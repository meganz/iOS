import MEGADomain
import MEGAPresentation

protocol VideoPlaylistThumbnailLoaderProtocol: Sendable {
    func loadThumbnails(for videos: [NodeEntity]) async -> [(any ImageContaining)]
}

struct VideoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoaderProtocol {
    
    private let maxThumbnailToBeDisplayedCount = 4
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private typealias TaskGroupThumbnails = TaskGroup<(order: Int, imageContainer: (any ImageContaining)?)>
    
    init(thumbnailLoader: any ThumbnailLoaderProtocol) {
        self.thumbnailLoader = thumbnailLoader
    }
    
    func loadThumbnails(for videos: [NodeEntity]) async -> [(any ImageContaining)] {
        await withTaskGroup(of: TaskGroupThumbnails.Element.self) { taskGroup -> [(any ImageContaining)] in

            let thumbnailToBeDisplayed = min(maxThumbnailToBeDisplayedCount, videos.count)
            var iterator = videos.enumerated().makeIterator()
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
            
            return results.sorted { a, b in a.order < b.order }
                .map(\.imageContainer)
        }
    }
}
