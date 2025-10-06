import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASdk
import SwiftUI
import Video

struct VideoRevampRouter: VideoRevampRouting {
    let explorerType: ExplorerTypeEntity
    let navigationController: UINavigationController?
    
    private let syncModel = VideoRevampSyncModel()
    private let nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    private var videoConfig: VideoConfig {
        .live()
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
            setAndElementsUpdatesProvider: SetAndElementUpdatesProvider()
        )
        let sensitiveDisplayPreferenceUseCase = makeSensitiveDisplayPreferenceUseCase()
        let viewModel = VideoRevampTabContainerViewModel(
            overDiskQuotaChecker: OverDiskQuotaChecker(
                accountStorageUseCase: AccountStorageUseCase(
                    accountRepository: AccountRepository.newRepo,
                    preferenceUseCase: PreferenceUseCase.default
                ),
                appDelegateRouter: AppDelegateRouter()),
            videoSelection: VideoSelection(),
            syncModel: syncModel)
        let photoLibraryRepository = PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
        let videoPlaylistUseCase = VideoPlaylistUseCase(
            fileSearchUseCase: fileSearchUseCase,
            userVideoPlaylistsRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase
        )
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
        let videoPlaylistContentsUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
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
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: sdk)),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: nodeRepository
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            videoConfig: .live(),
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
        guard let selectedNode = nodeInfoUseCase.node(for: video.handle) else { return }
        let allNodes = allVideos.compactMap { nodeInfoUseCase.node(for: $0.handle) }
        
        guard let navigationController else { return }
        let nodeOpener = NodeOpener(navigationController: navigationController)
        nodeOpener.openNode(node: selectedNode, allNodes: allNodes)
    }
    
    func openMoreOptions(for videoNodeEntity: NodeEntity, sender: Any, shouldShowSelection: Bool) {
        guard
            let navigationController,
            let videoMegaNode = videoNodeEntity.toMEGANode(in: MEGASdk.shared)
        else {
            return
        }

        let nodeActionResponder = NodeActionResponder { [weak syncModel] nodes in
            syncModel?.selectVideos(nodes.map { $0.toNodeEntity() })
        }

        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUseCase.isBackupNode(videoNodeEntity)
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(
                presenter: navigationController),
            nodeActionListener: nodeActionResponder.nodeActionListener()
        )
        let overDiskQuotaNodeActionDelegate = OverDiskQuotaNodeActionViewControllerDelegate(
            delegate: delegate,
            overDiskQuotaChecker: OverDiskQuotaChecker(
                accountStorageUseCase: AccountStorageUseCase(
                    accountRepository: AccountRepository.newRepo,
                    preferenceUseCase: PreferenceUseCase.default
                ),
                appDelegateRouter: AppDelegateRouter()),
            overDiskActions: [.saveToPhotos, .download, .shareLink, .manageLink,
                              .removeLink, .exportFile, .rename, .copy, .move, .moveToRubbishBin]
        )
        let viewController = NodeActionViewController(
            node: videoMegaNode,
            delegate: overDiskQuotaNodeActionDelegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            isSelectionEnabled: DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) && shouldShowSelection,
            sender: sender
        )
        viewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) {
        let userVideoPlaylistsRepo = UserVideoPlaylistsRepository.newRepo
        let fileSearchRepo = FilesSearchRepository.newRepo
        let sensitiveDisplayPreferenceUseCase = makeSensitiveDisplayPreferenceUseCase()
        let photoLibraryRepository = PhotoLibraryRepository(cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        let photoLibraryUseCase = PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: fileSearchRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
        let nodeRepository = NodeRepository.newRepo
        let accountUseCase = AccountUseCase(
            repository: AccountRepository.newRepo)
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: accountUseCase)
        let videoPlaylistContentsUseCase = VideoPlaylistContentsUseCase(
            userVideoPlaylistRepository: userVideoPlaylistsRepo,
            photoLibraryUseCase: photoLibraryUseCase,
            fileSearchRepository: fileSearchRepo,
            nodeRepository: nodeRepository,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
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
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: nodeRepository
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            router: self,
            presentationConfig: presentationConfig,
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: PreferenceUseCase.default,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
            ),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: MEGASdk.shared)),
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
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
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: nodeRepository
        )
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let sensitiveNodeUseCase = SensitiveNodeUseCase(nodeRepository: nodeRepository, accountUseCase: accountUseCase)
        let nodeIconUseCase = NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: sdk))
        let recenltyOpenedNodesRepository = RecentlyOpenedNodesRepository(store: MEGAStore.shareInstance(), sdk: sdk)
        let recenltyOpenedNodeUseCase = RecentlyOpenedNodesUseCase(recentlyOpenedNodesRepository: recenltyOpenedNodesRepository)
        let viewController = RecentlyWatchedVideosViewController(
            videoConfig: .live(),
            recentlyOpenedNodesUseCase: recenltyOpenedNodeUseCase,
            sharedUIState: RecentlyWatchedVideosSharedUIState(),
            router: self,
            thumbnailLoader: VideoRevampFactory.makeThumbnailLoader(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeIconUseCase: nodeIconUseCase
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: DIContainer.featureFlagProvider
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> some View {
        let viewModel = EnforceCopyrightWarningViewModel(
            preferenceUseCase: PreferenceUseCase.default,
            copyrightUseCase: CopyrightUseCase(
                shareUseCase: ShareUseCase(
                    shareRepository: ShareRepository.newRepo,
                    filesSearchRepository: FilesSearchRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                )
            )
        )
        return EnforceCopyrightWarningView(viewModel: viewModel) {
            GetVideoPlaylistsLinksViewWrapper(videoPlaylist: videoPlaylist)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }
    }
    
    func showOverDiskQuota() {
        AppDelegateRouter().showOverDiskQuota()
    }
    
    private func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
}

struct ShareEmptyView: View {
    var body: some View {
        Text("TBD")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
