import Combine
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

@MainActor
final class FolderLinkMediaDiscoveryContentViewModel: ObservableObject, MediaDiscoveryContentDelegate {
    @Published var editMode: EditMode = .inactive
    @Published var selectedPhotos: [NodeEntity] = []
    
    lazy var mediaDiscoveryContentViewModel: MediaDiscoveryContentViewModel = {
        let mediaAnalyticsUseCase = MediaDiscoveryAnalyticsUseCase(
            repository: AnalyticsRepository(sdk: MEGASdk.sharedFolderLink)
        )
        let mediaDiscoveryUseCase = MediaDiscoveryUseCase(
            filesSearchRepository: FilesSearchRepository(sdk: MEGASdk.sharedFolderLink),
            nodeUpdateRepository: NodeUpdateRepository.newRepo,
            isFolderLink: true
        )
        let contentConsumptionUserAttributeUseCase = ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository(sdk: MEGASdk.sharedFolderLink))
        
        return MediaDiscoveryContentViewModel(
            contentMode: .mediaDiscoveryFolderLink,
            parentNodeProvider: { MEGASdk.sharedFolderLink.node(forHandle: self.nodeHandle)?.toNodeEntity() },
            sortOrder: sortOrder,
            isAutomaticallyShown: false,
            delegate: self,
            analyticsUseCase: mediaAnalyticsUseCase,
            mediaDiscoveryUseCase: mediaDiscoveryUseCase,
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo,
                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
                ),
                contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                hiddenNodesFeatureFlagEnabled: { false }
            )
        )
    }()
    
    private let nodeHandle: HandleEntity
    private let sortOrder: SortOrderType
    private var subscriptions: Set<AnyCancellable> = []
    
    init(
        nodeHandle: HandleEntity,
        sortOrder: SortOrderType
    ) {
        self.nodeHandle = nodeHandle
        self.sortOrder = sortOrder
        
        $editMode
            .sink { [weak self] mode in
                self?.mediaDiscoveryContentViewModel.editMode = mode
            }
            .store(in: &subscriptions)
    }
    
    func selectedPhotos(selected: [MEGADomain.NodeEntity], allPhotos: [MEGADomain.NodeEntity]) {
        selectedPhotos = selected
    }
    
    func isMediaDiscoverySelection(isHidden: Bool) {}
    
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {}
    
    func toggleSelectAll() {
        mediaDiscoveryContentViewModel.toggleAllSelected()
    }
}
