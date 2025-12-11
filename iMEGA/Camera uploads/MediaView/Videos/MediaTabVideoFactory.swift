import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASdk
import Video

struct MediaTabVideoFactory {
    @MainActor static func makeVideoTabViewModel(
        syncModel: VideoRevampSyncModel,
        videoSelection: VideoSelection,
        navigationController: UINavigationController?
    ) -> VideoTabViewModel {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSearchRepo = FilesSearchRepository(sdk: sdk)
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeRepository: nodeRepository
        )

        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )

        let sensitiveDisplayPreferenceUseCase = SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: nodeRepository,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            ),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo
            ),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )

        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )

        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))

        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: nodeRepository
        )

        let thumbnailLoader = VideoRevampFactory.makeThumbnailLoader(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared)
        )

        let videoListViewModel = VideoListViewModel(
            syncModel: syncModel,
            contentProvider: VideoListViewModelContentProvider(
                photoLibraryUseCase: photoLibraryUseCase
            ),
            selection: videoSelection,
            fileSearchUseCase: fileSearchUseCase,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: DIContainer.featureFlagProvider,
            shouldShowFilterChip: false
        )

        let router = VideoRevampRouter(
            explorerType: .video,
            navigationController: navigationController
        )

        return VideoTabViewModel(
            videoListViewModel: videoListViewModel,
            videoSelection: videoSelection,
            syncModel: syncModel,
            videoConfig: .live(),
            router: router,
            featureFlagProvider: DIContainer.featureFlagProvider
        )
    }
}
