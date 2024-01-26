import MEGADomain
import UIKit

struct Preview_VideoRevampRouter: VideoRevampRouting {
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
}
