import Combine
import CoreSpotlight
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import UniformTypeIdentifiers

final class SpotlightIndexer: NSObject {
    
    private let contentIndexerActor: SpotlightContentIndexerActor
    private let spotlightSearchableIndexUseCase: any SpotlightSearchableIndexUseCaseProtocol
    private var favouritesIndexed: Bool = false
    private var passcodeEnabled: Bool
 
    @objc init(sdk: MEGASdk, passcodeEnabled: Bool = false) {
        self.passcodeEnabled = passcodeEnabled
        self.spotlightSearchableIndexUseCase = SpotlightSearchableIndexUseCase(
            spotlightRepository: SpotlightRepository.newRepo)
        
        self.contentIndexerActor = SpotlightContentIndexerActor(
            favouritesUseCase: FavouriteNodesUseCase(
                repo: FavouriteNodesRepository.newRepo,
                nodeRepository: NodeRepository.newRepo,
                sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo,
                        accountUseCase: AccountUseCase(
                            repository: AccountRepository.newRepo)
                    ),
                    contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                        repo: UserAttributeRepository.newRepo),
                    hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })),
            nodeAttributeUseCase: NodeAttributeUseCase(
                repo: NodeAttributeRepository.newRepo),
            spotlightSearchableIndexUseCase: spotlightSearchableIndexUseCase,
            nodeUpdatesProvider: NodeUpdatesProvider(sdk: sdk)
        )
        super.init()
    }
    
    @objc func indexFavourites() async {
        guard shouldIndexFavourites() else {
            return
        }
        
        await contentIndexerActor.indexSearchableItems()
        favouritesIndexed = true
    }
    
    @objc func deindexAllSearchableItems() async {
        await contentIndexerActor.deleteAllSearchableItems()
        favouritesIndexed = false
    }
    
    // MARK: - Private
    
    private func shouldIndexFavourites() -> Bool {
        let isIndexingAvailable = spotlightSearchableIndexUseCase.isIndexingAvailable
        guard !favouritesIndexed, !passcodeEnabled, isIndexingAvailable else {
            MEGALogDebug("[Spotlight] Favourites indexed: \(favouritesIndexed)")
            MEGALogDebug("[Spotlight] Passcode enabled: \(passcodeEnabled)")
            MEGALogDebug("[Spotlight] Is indexing available: \(isIndexingAvailable)")
            return false
        }
        return true
    }
}
