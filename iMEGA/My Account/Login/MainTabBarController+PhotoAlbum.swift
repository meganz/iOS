import MEGADomain
import UIKit

extension MainTabBarController {
    @objc func photoAlbumViewController() -> MEGANavigationController? {
        let storyboard = UIStoryboard(name: "Photos", bundle: nil)
        let photosAlbumNavigationController = storyboard.instantiateViewController(withIdentifier: "photosAlbumNavigationController")
        return photosAlbumNavigationController as? MEGANavigationController
    }
}
