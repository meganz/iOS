import SwiftUI
import UIKit

extension VideoRevampFactory {
    
    public static func makeRecentlyWatchedVideosView(videoConfig: VideoConfig) -> UIViewController {
        let view = RecentlyWatchedVideosView(videoConfig: videoConfig)
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        return viewController
    }
}
