import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import UIKit

struct SlideShowRouter: Routing {
    private weak var presenter: UIViewController?
    private let dataProvider: PhotoBrowserDataProvider
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    init(
        dataProvider: PhotoBrowserDataProvider,
        presenter: UIViewController?,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.dataProvider = dataProvider
        self.presenter = presenter
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
    }
    
    private func configSlideShowViewModel() -> SlideShowViewModel {
        let photoEntities = dataProvider.fetchOnlyPhotoEntities(mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo))
        
        var preferenceRepo: PreferenceRepository
        if let slideshowUserDefaults = UserDefaults(suiteName: "slideshow") {
            preferenceRepo = PreferenceRepository(userDefaults: slideshowUserDefaults)
        } else {
            preferenceRepo = PreferenceRepository.newRepo
        }
        
        return SlideShowViewModel(dataSource: slideShowDataSource(photos: photoEntities),
                                  slideShowUseCase: SlideShowUseCase(preferenceRepo: preferenceRepo),
                                  accountUseCase: AccountUseCase(repository: AccountRepository.newRepo), 
                                  tracker: tracker)
    }

    private func configLegacySlideShowViewModel() -> LegacySlideShowViewModel {
        let photoEntities = dataProvider.fetchOnlyPhotoEntities(mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo))

        var preferenceRepo: PreferenceRepository
        if let slideshowUserDefaults = UserDefaults(suiteName: "slideshow") {
            preferenceRepo = PreferenceRepository(userDefaults: slideshowUserDefaults)
        } else {
            preferenceRepo = PreferenceRepository.newRepo
        }

        return LegacySlideShowViewModel(dataSource: slideShowDataSource(photos: photoEntities),
                                        slideShowUseCase: SlideShowUseCase(preferenceRepo: preferenceRepo),
                                        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                                        tracker: tracker)
    }

    private func slideShowDataSource(photos: [NodeEntity]) -> SlideShowDataSource {
        SlideShowDataSource(
            currentPhoto: dataProvider.currentPhotoNodeEntity,
            nodeEntities: photos,
            thumbnailUseCase: dataProvider.makeThumbnailUseCase(),
            fileDownloadUseCase: FileDownloadUseCase(fileCacheRepository: FileCacheRepository.newRepo,
                                                     fileSystemRepository: FileSystemRepository.sharedRepo,
                                                     downloadFileRepository: DownloadFileRepository.newRepo),
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            advanceNumberOfPhotosToLoad: 10
        )
    }

    func build() -> UIViewController {
        let storyboard: UIStoryboard = UIStoryboard(name: "Slideshow", bundle: nil)

        let vc = storyboard.instantiateInitialViewController { coder in
            SlideShowViewController(coder: coder, viewModel: configSlideShowViewModel())
        }
        return vc!
    }
    
    func start() {
        presenter?.present(build(), animated: true)
    }
}
