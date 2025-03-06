import ContentLibraries
import MEGADomain
import SwiftUI
import Video

struct MockVideoRevampRouter: VideoRevampRouting {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func openMoreOptions(for video: NodeEntity, sender: Any) { }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) { }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) { }
    
    func openRecentlyWatchedVideos() { }
    
    func popScreen() { }
    
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> some View { EmptyView() }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
    
    func showOverDiskQuota() { }
}
