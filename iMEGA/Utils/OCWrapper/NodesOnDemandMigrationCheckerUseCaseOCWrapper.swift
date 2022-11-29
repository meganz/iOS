import MEGADomain
import MEGAData

@objc class NodesOnDemandMigrationCheckerUseCaseOCWrapper: NSObject {
    let useCase = NodesOnDemandMigrationCheckerUseCase(megaclientRepository: MEGAClientRepository.newRepo, statsRepository: StatsRepository.newRepo)
    
    @objc func doesExistNodesOnDemandDatabase(with session: SessionIdEntity) -> Bool {
        useCase.doesExistNodesOnDemandDatabase(with: session)
    }
    
    @objc func sendExtensionsWithoutNoDStats() {
        useCase.sendExtensionsWithoutNoDStats()
    }
}
