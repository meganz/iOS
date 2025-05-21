import MEGAAssets
import MEGADomain
import UIKit

extension MainTabBarController {
    @objc func photoAlbumViewController() -> MEGANavigationController? {
        let storyboard = UIStoryboard(name: "Photos", bundle: nil)
        let photosAlbumNavigationController = storyboard.instantiateViewController(withIdentifier: "photosAlbumNavigationController")
        photosAlbumNavigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: MEGAAssets.UIImage.cameraUploadsIcon,
            selectedImage: nil
        )
        return photosAlbumNavigationController as? MEGANavigationController
    }
}
