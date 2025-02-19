import ContentLibraries
import MEGADomain
import MEGASDKRepo

extension AppDelegate {
    
    @objc func initialiseModules() {
        ContentLibraries.configuration = .init(
            sensitiveNodeUseCase: makeSensitiveNodeUseCase(),
            nodeUseCase: makeNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: {
                AlbumRemoteFeatureFlagProvider().isPerformanceImprovementsEnabled()
            }
        )
    }
    
    private func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
          nodeRepository: NodeRepository.newRepo,
          accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
    }
    
    private func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }
}
