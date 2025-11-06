import ContentLibraries
import MEGADomain
import SwiftUI
import UIKit
import Video

final class MockVideoRevampRouter: VideoRevampRouting {
    private(set) var openVideoPickerCalled = 0
    private(set) var showOverDiskQuotaCalled = 0
    
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }

    func openMoreOptions(for video: NodeEntity, sender: Any, shouldShowSelection: Bool) { }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) { }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) {
        openVideoPickerCalled += 1
    }
    
    func popScreen() { }
    
    func openRecentlyWatchedVideos() { }
    
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> some View { EmptyView() }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
    
    func showOverDiskQuota() {
        showOverDiskQuotaCalled += 1
    }
}
