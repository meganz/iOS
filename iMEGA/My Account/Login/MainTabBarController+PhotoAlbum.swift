import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import UIKit

extension MainTabBarController {
    @objc func photoAlbumViewController() -> UIViewController? {
        let isMediaRevampEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)

        if isMediaRevampEnabled {
            return makeMediaTabViewController()
        } else {
            return makeLegacyPhotoAlbumViewController()
        }
    }

    // MARK: - Private Methods

    private func makeMediaTabViewController() -> UIViewController {
        MediaTabViewControllerFactory.make().build()
    }

    private func makeLegacyPhotoAlbumViewController() -> MEGANavigationController? {
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
