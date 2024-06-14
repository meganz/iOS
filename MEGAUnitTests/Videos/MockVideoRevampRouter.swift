import MEGADomain
import Video

struct MockVideoRevampRouter: VideoRevampRouting {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func openMoreOptions(for video: NodeEntity, sender: Any) { }
    
    func openVideoPlaylistContent(for previewEntity: VideoPlaylistEntity) { }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) { }
    
    func popScreen() { }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
}
