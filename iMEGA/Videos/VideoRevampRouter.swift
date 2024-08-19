import MEGADomain
import MEGAPresentation
import MEGASdk
import MEGASDKRepo
import Video

struct VideoRevampRouter: VideoRevampRouting {
    let explorerType: ExplorerTypeEntity
    let navigationController: UINavigationController?
    let isDesignTokenEnabled: Bool
    
    private let syncModel = VideoRevampSyncModel()
    
    private var videoConfig: VideoConfig {
        .live(isDesignTokenEnabled: isDesignTokenEnabled)
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSearchRepo = FilesSearchRepository(sdk: sdk)
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeRepository: nodeRepository
        )
        let userVideoPlaylistsRepo = UserVideoPlaylistsRepository(
            sdk: sdk,
            setAndElementsUpdatesProvider: SetAndElementUpdatesProvider(sdk: sdk)
        )
        let contentConsumptionUserAttributeUseCase = ContentConsumptionUserAttributeUseCase(
            repo: UserAttributeRepository.newRepo)
        let viewModel = VideoRevampTabContainerViewModel(videoSelection: VideoSelection(), syncModel: syncModel)
        let photoLibraryRepository = PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        let videoPlaylistUseCase = VideoPlaylistUseCase(
            fileSearchUseCase: fileSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistsRepo, 
            photoLibraryUseCase: photoLibraryUseCase
        )
        let videoPlaylistContentsUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            sensitiveNodeUseCase: SensitiveNodeUseCase(nodeRepository: nodeRepository)) {
                DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        let videoPlaylistModificationUseCase = VideoPlaylistModificationUseCase(
            userVideoPlaylistsRepository: userVideoPlaylistsRepo
        )
        let viewController = VideoRevampTabContainerViewController(
            viewModel: viewModel,
            fileSearchUseCase: fileSearchUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            videoPlaylistUseCase: videoPlaylistUseCase,
            videoPlaylistContentUseCase: videoPlaylistContentsUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: PreferenceUseCase.default,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
            ),
            videoConfig: .live(isDesignTokenEnabled: isDesignTokenEnabled),
            router: self,
            featureFlagProvider: DIContainer.featureFlagProvider
        )
        return viewController
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) {
        let nodeInfoUseCase = NodeInfoUseCase()
        guard let selectedNode = nodeInfoUseCase.node(fromHandle: video.handle) else { return }
        let allNodes = allVideos.compactMap { nodeInfoUseCase.node(fromHandle: $0.handle) }
        
        guard let navigationController else { return }
        let nodeOpener = NodeOpener(navigationController: navigationController)
        nodeOpener.openNode(node: selectedNode, allNodes: allNodes)
    }
    
    func openMoreOptions(for videoNodeEntity: NodeEntity, sender: Any) {
        guard
            let navigationController,
            let videoMegaNode = videoNodeEntity.toMEGANode(in: MEGASdk.shared)
        else {
            return
        }
        
        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUseCase.isBackupNode(videoNodeEntity)
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
        )
        let viewController = NodeActionViewController(
            node: videoMegaNode,
            delegate: delegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: sender
        )
        
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) {
        let userVideoPlaylistsRepo = UserVideoPlaylistsRepository.newRepo
        let fileSearchRepo = FilesSearchRepository.newRepo
        let contentConsumptionUserAttributeUseCase = ContentConsumptionUserAttributeUseCase(
            repo: UserAttributeRepository.newRepo)
        let photoLibraryRepository = PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        let nodeRepository = NodeRepository.newRepo
        let videoPlaylistContentsUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            sensitiveNodeUseCase: SensitiveNodeUseCase(nodeRepository: nodeRepository),
            hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        let thumbnailUseCase = ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        let videoSelection = VideoSelection()
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeRepository: nodeRepository
        )
        let videoPlaylistUseCase = VideoPlaylistUseCase(
            fileSearchUseCase: fileSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase
        )
        let videoPlaylistModificationUseCase = VideoPlaylistModificationUseCase(
            userVideoPlaylistsRepository: userVideoPlaylistsRepo
        )
        let viewController = VideoPlaylistContentViewController(
            videoConfig: videoConfig,
            videoPlaylistEntity: videoPlaylistEntity,
            videoPlaylistContentsUseCase: videoPlaylistContentsUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoPlaylistUseCase: videoPlaylistUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            router: self,
            presentationConfig: presentationConfig,
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: PreferenceUseCase.default,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
            ),
            videoSelection: videoSelection,
            selectionAdapter: VideoPlaylistContentViewModelSelectionAdapter(selection: videoSelection),
            syncModel: syncModel
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) {
        guard
            let browserNavigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
            let browserVC = browserNavigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.browserAction = BrowserAction.selectVideo
        browserVC.selectedNodes = { selectedObjects in
            guard let selectedNodes = selectedObjects as? [MEGANode] else {
                completion([])
                return
            }
            completion(selectedNodes.toNodeEntities())
        }
        
        navigationController?.present(browserNavigationController, animated: true)
    }
    
    func popScreen() {
        navigationController?.popViewController(animated: true)
    }
    
    func openRecentlyWatchedVideos() {
        let viewController = RecentlyWatchedVideosViewController(videoConfig: .live(isDesignTokenEnabled: isDesignTokenEnabled))
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
}
