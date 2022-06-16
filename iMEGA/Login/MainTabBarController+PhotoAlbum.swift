import UIKit

@available(iOS 14.0, *)
extension MainTabBarController {
    @objc func photoAlbumViewController() -> MEGANavigationController? {
        let storyboard = UIStoryboard(name: "Photos", bundle: nil)
        let photosAlbumNavigationController = storyboard.instantiateViewController(withIdentifier: "photosAlbumNavigationController")
        return photosAlbumNavigationController as? MEGANavigationController
    }
    
    @objc func photoViewController() -> MEGANavigationController? {
        let storyboard = UIStoryboard(name: "Photos", bundle: nil)
        
        if let navigationController = storyboard.instantiateInitialViewController() as? MEGANavigationController,
           let photosVC = navigationController.viewControllers.first as? PhotosViewController {
            photosVC.configureMyAvatarManager()
            
            let photoUpdatePublisher = PhotoUpdatePublisher(photosViewController: photosVC)
            let photoLibraryRepository = PhotoLibraryRepository.default
            let fileSearchRepository = SDKFilesSearchRepository.default
            let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository, searchRepository: fileSearchRepository)
            let viewModel = PhotoViewModel(
                photoUpdatePublisher: photoUpdatePublisher,
                photoLibraryUseCase: photoLibraryUseCase
            )
            
            photosVC.viewModel = viewModel
            photosVC.photoUpdatePublisher = photoUpdatePublisher
            
            return navigationController
        }
        
        return nil
    }
}
