import UIKit
import MEGADomain
import MEGAData

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
        let mediaUseCase = MediaUseCase()
        let slideShowViewModel = SlideShowViewModel(
            dataSource: SlideShowDataSource(
                currentPhoto: dataProvider.currentPhoto?.toNodeEntity(),
                nodeEntities: dataProvider.allPhotoEntities.filter { mediaUseCase.isImage($0.name) },
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
                mediaUseCase: mediaUseCase,
                advanceNumberOfPhotosToLoad: 20,
                numberOfUnusedPhotosBuffer: 20
            ),
            slideShowUseCase: SlideShowUseCase(slideShowRepository: SlideShowRepository.newRepo)
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
