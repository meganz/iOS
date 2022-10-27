import UIKit
import MEGADomain

struct SlideShowRouter: Routing {
    private let homeViewController: MEGAPhotoBrowserViewController
    private let dataProvider: PhotoBrowserDataProvider
    
    init(
        dataProvider: PhotoBrowserDataProvider,
        megaPhotoBrowserViewController: MEGAPhotoBrowserViewController
    ) {
        self.dataProvider = dataProvider
        self.homeViewController = megaPhotoBrowserViewController
    }
    
    func build() -> UIViewController {
        let slideShowViewModel = SlideShowViewModel(
            dataSource: SlideShowDataSource(
                currentPhoto: dataProvider.currentPhoto?.toNodeEntity(),
                nodeEntities: dataProvider.allPhotoEntities,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
                mediaUseCase: MediaUseCase(),
                advanceNumberOfPhotosToLoad: 20,
                numberOfUnusedPhotosBuffer: 20
            ),
            configuration: .init(
                playingOrder: .shuffled,
                timeIntervalForSlideInSeconds: .normal,
                isRepeat: false,
                includeSubfolders: false
            )
        )
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Slideshow", bundle: nil)
        let slideShowVC = storyboard.instantiateInitialViewController() as! SlideShowViewController
        slideShowVC.update(viewModel: slideShowViewModel)
        
        return slideShowVC
    }
    
    func start() {
        guard let slideshowVC = build() as? SlideShowViewController else { return }
        homeViewController.present(slideshowVC, animated: true)
    }
}
