import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import UIKit

extension MainTabBarController {
    @objc func photoAlbumViewController() -> UIViewController? {
        MediaTabViewControllerFactory.make().build()
    }
}
