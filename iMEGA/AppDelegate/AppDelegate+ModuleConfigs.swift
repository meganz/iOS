import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Transfer

extension AppDelegate {
    
    @objc func initialiseModules() {
        ContentLibraries.configuration = .init(
            sensitiveNodeUseCase: makeSensitiveNodeUseCase(),
            remoteFeatureFlagUseCase: RemoteFeatureFlagUseCase(repository: RemoteFeatureFlagRepository.newRepo),
            featureFlagProvider: DIContainer.featureFlagProvider,
            nodeUseCase: makeNodeUseCase()
        )
    }
    
    @objc func configureTransferServices() {
        MainActor.assumeIsolated {
            SharedTransferIndicator.configure()
            if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newTransfers) {
                SharedTransferFinishRecorder.shared.configure()
            }
        }
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
