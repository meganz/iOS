import MEGADomain
import MEGASDKRepo
import Video

struct VideoRevampRouter: VideoRevampRouting {
    let explorerType: ExplorerTypeEntity
    let navigationController: UINavigationController?
    let isDesignTokenEnabled: Bool
    
    func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let nodesUpdateListenerRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let fileSearchRepo = FilesSearchRepository(sdk: sdk)
        let fileSearchUseCase = FilesSearchUseCase(
            repo: fileSearchRepo,
            nodeFormat: explorerType.toNodeFormatEntity(),
            nodesUpdateListenerRepo: nodesUpdateListenerRepo
        )
        let viewModel = VideoRevampTabContainerViewModel()
        let thumbnailUseCase = ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        let viewController = VideoRevampTabContainerViewController(
            viewModel: viewModel,
            fileSearchUseCase: fileSearchUseCase,
            thumbnailUseCase: thumbnailUseCase,
            videoConfig: .live(isDesignTokenEnabled: isDesignTokenEnabled),
            router: self
        )
        return viewController
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) {
        guard
            video.mediaType == .video,
            allVideos.allSatisfy({ $0.mediaType == .video })
        else {
            return
        }
        
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
        let delegate = NodeActionViewControllerGenericDelegate(viewController: navigationController)
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
}
