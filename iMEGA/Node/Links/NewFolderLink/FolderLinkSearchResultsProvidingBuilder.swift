import FolderLink
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import MEGASdk
import MEGASwift
import Search

struct FolderLinkSearchResultsUpdatesProvider: SearchResultsUpdatesProvider {
    let nodeRepository: NodeRepository
    
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.folderLinkNodeUpdates
    }
}

struct FolderLinkSearchResultsProvidingBuilder: FolderLinkSearchResultsProvidingBuilderProtocol {
    func build(with handle: HandleEntity) -> any SearchResultsProviding {
        let sharedFolderLink = MEGASdk.sharedFolderLink
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository(sdk: sdk, sharedFolderSdk: sharedFolderLink, nodeUpdatesProvider: NodeUpdatesProvider())
        let downloadedNodesListener = CloudDriveDownloadedNodesListener(
            subListeners: [
                CloudDriveDownloadTransfersListener(
                    sdk: sharedFolderLink,
                    transfersListenerUsecase: TransfersListenerUseCase(
                        repo: TransfersListenerRepository.newRepo,
                        preferenceUseCase: PreferenceUseCase.default
                    ),
                    fileSystemRepo: FileSystemRepository.sharedRepo
                ),
                NodesSavedToOfflineListener(notificationCenter: .default)
            ]
        )
        let filesSearchUseCase = FilesSearchUseCase(repo: FilesSearchRepository(sdk: sharedFolderLink), nodeRepository: nodeRepository)
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository(sdk: sdk, sharedFolderSdk: sharedFolderLink),
            nodeValidationRepository: NodeValidationRepository.folderLink,
            nodeRepository: nodeRepository
        )
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let sensitiveNodeUseCase = SensitiveNodeUseCase(nodeRepository: nodeRepository, accountUseCase: accountUseCase)
        let contentConsumptionUserAttributeUseCase = ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository(sdk: sharedFolderLink))
        let sénitiveDisplayPreferenceUseCase = SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { false }
        )
        
        let searchResultMapper = FolderLinkSearchResultMapper(
            sdk: sharedFolderLink,
            nodeValidationRepository: NodeValidationRepository.folderLink,
            nodeDataRepository: NodeDataRepository.newRepo,
            thumbnailRepository: ThumbnailRepository.folderLinkThumbnailRepository(),
            nodeIconRepository: NodeAssetsManager.shared
        )
        
        return HomeSearchResultsProvider(
            parentNodeProvider: { sharedFolderLink.node(forHandle: handle)?.toNodeEntity() },
            filesSearchUseCase: filesSearchUseCase,
            nodeUseCase: nodeUseCase,
            downloadedNodesListener: downloadedNodesListener,
            sensitiveDisplayPreferenceUseCase: sénitiveDisplayPreferenceUseCase,
            resultsMapper: searchResultMapper,
            resultsUpdates: FolderLinkSearchResultsUpdatesProvider(nodeRepository: nodeRepository),
            allChips: SearchChipEntity.allChips(currentDate: { .init() }, calendar: .autoupdatingCurrent),
            sdk: sharedFolderLink,
            hiddenNodesFeatureEnabled: false,
            isFromSharedItem: false
        )
    }
}
