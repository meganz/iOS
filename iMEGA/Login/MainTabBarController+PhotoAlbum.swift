import UIKit

@available(iOS 14.0, *)
extension MainTabBarController {
    @objc func photoAlbumViewController() -> MEGANavigationController? {
        if FeatureFlag.isAlbumEnabled {
            let storyboard = UIStoryboard(name: "Photos", bundle: nil)
            let photosAlbumNavigationController = storyboard.instantiateViewController(withIdentifier: "photosAlbumNavigationController")
            return photosAlbumNavigationController as? MEGANavigationController
        } else {
            return photoViewController()
        }
    }
    
    @objc func photoViewController() -> MEGANavigationController? {
        let storyboard = UIStoryboard(name: "Photos", bundle: nil)
        
        if let navigationController = storyboard.instantiateInitialViewController() as? MEGANavigationController,
           let photosVC = navigationController.viewControllers.first as? PhotosViewController {
            photosVC.configureMyAvatarManager()
            
            return navigationController
        }
        
        return nil
    }
}
