import ChatRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import UIKit

struct SlideShowRouter: Routing {
    private weak var presenter: UIViewController?
    private let dataProvider: PhotoBrowserDataProvider
    private let photos: [NodeEntity]?
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    /// - Parameter photos: the whole image sequence, for a browser that holds only part of it.
    ///   `nil` where the provider's own array is already all of it, which is every entry point but
    ///   the paginated timeline.
    init(
        dataProvider: PhotoBrowserDataProvider,
        presenter: UIViewController?,
        photos: [NodeEntity]? = nil,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.dataProvider = dataProvider
        self.presenter = presenter
        self.photos = photos
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
    }

    private var photoEntities: [NodeEntity] {
        photos ?? dataProvider.fetchOnlyPhotoEntities(
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo))
    }
    
    private func configSlideShowViewModel() -> SlideShowViewModel {
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
        let downloadRepository = DownloadFileRepository(
            sdk: MEGASdk.shared,
            chatNodeProvider: ChatMEGANodeProvider(chatSdk: MEGAChatSdk.sharedChatSdk, sdk: MEGASdk.shared)
        )
        
        return SlideShowDataSource(
            currentPhoto: dataProvider.currentPhotoNodeEntity,
            nodeEntities: photos,
            thumbnailUseCase: dataProvider.makeThumbnailUseCase(),
            fileDownloadUseCase: FileDownloadUseCase(
                fileCacheRepository: FileCacheRepository.newRepo,
                fileSystemRepository: FileSystemRepository.sharedRepo,
                downloadFileRepository: downloadRepository
            ),
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
