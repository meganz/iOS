import MEGAData
import MEGADomain

@objc class NodesOnDemandMigrationCheckerUseCaseOCWrapper: NSObject {
    let useCase = NodesOnDemandMigrationCheckerUseCase(megaclientRepository: MEGAClientRepository.newRepo, analyticsEventUseCase: AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: MEGASdkManager.sharedMEGASdk())))
    
    @objc func doesExistNodesOnDemandDatabase(with session: SessionIdEntity) -> Bool {
        useCase.doesExistNodesOnDemandDatabase(with: session)
    }
    
    @objc func sendExtensionsWithoutNoDStats() {
        useCase.sendExtensionsWithoutNoDStats()
    }
}
