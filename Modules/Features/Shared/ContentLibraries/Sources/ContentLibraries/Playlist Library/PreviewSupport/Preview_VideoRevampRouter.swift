import MEGADomain
import SwiftUI
import UIKit

struct Preview_VideoRevampRouter: VideoRevampRouting {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func openMoreOptions(for video: NodeEntity, sender: Any, shouldShowSelection shouldShowDeleteOption: Bool) { }

    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) { }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) { }
    
    func popScreen() { }
    
    func openRecentlyWatchedVideos() { }
    
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> some View { EmptyView() }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
    
    func showOverDiskQuota() { }
}
