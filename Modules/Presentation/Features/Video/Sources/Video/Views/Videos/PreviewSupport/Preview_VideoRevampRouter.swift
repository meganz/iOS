import MEGADomain
import UIKit

struct Preview_VideoRevampRouter: VideoRevampRouting {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func openMoreOptions(for video: NodeEntity, sender: Any) { }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
}
