import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAFoundation
import MEGARepo
import Transfer

extension AppDelegate {
    
    @objc func initialiseModules() {
        ContentLibraries.configuration = .init(
            sensitiveNodeUseCase: makeSensitiveNodeUseCase(),
            remoteFeatureFlagUseCase: RemoteFeatureFlagUseCase(repository: RemoteFeatureFlagRepository.newRepo),
            featureFlagProvider: DIContainer.featureFlagProvider,
            nodeUseCase: Self.makeNodeUseCase(),
            makeOfflineFileOpenGuard: {
                OfflineFileOpenGuard(
                    isNewOfflineModeEnabled: DIContainer.featureFlagProvider.isNewOfflineModeEnabled,
                    networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                    nodeUseCase: AppDelegate.makeNodeUseCase(),
                    thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
                )
            }
        )
    }
    
    @objc func configureTransferServices() {
        MainActor.assumeIsolated {
            SharedTransferIndicator.configure()
            if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newTransfers) {
                SharedTransferFinishRecorder.shared.configure()
            } else {
                Task {
                    let isTransfersRevampEnabled = await AsyncUtils.timeout(30, default: false) {
                        await DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabledAfterReady(for: .iosTransfersRevamp)
                    }

                    guard isTransfersRevampEnabled else { return }

                    SharedTransferFinishRecorder.shared.configure()
                }
            }
        }
    }
    
    private func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
          nodeRepository: NodeRepository.newRepo,
          accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
    }
    
    private nonisolated static func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }
}
