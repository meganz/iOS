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
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            dataProvider: dataProvider,
            mediaUseCase: MediaUseCase(),
            configuration: .init(playingOrder: .shuffled, timeIntervalForSlideInSeconds: 4)
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
