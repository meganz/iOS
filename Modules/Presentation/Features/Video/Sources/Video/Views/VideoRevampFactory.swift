import SwiftUI

public class VideoRevampFactory {
    public static func makeTabContainerView(videoConfig: VideoConfig) -> UIViewController {
        return UIHostingController(rootView: TabContainerView(videoConfig: videoConfig))
    }
    
    public static func makeToolbarView(isDisabled: Bool, videoConfig: VideoConfig) -> UIViewController {
        let controller = UIHostingController(rootView: VideoToolbar(videoConfig: videoConfig, isDisabled: isDisabled))
        controller.view.backgroundColor = .clear
        return controller
    }
}
