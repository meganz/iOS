import MEGADomain
import Video

struct MockVideoRevampRouter: VideoRevampRouting {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func openMoreOptions(for video: NodeEntity, sender: Any) { }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) { }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) { }
    
    func openRecentlyWatchedVideos() { }
    
    func popScreen() { }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
}
