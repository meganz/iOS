import Foundation

public typealias SessionIdEntity = String

public protocol NodesOnDemandMigrationCheckerUseCaseProtocol {
    func doesExistNodesOnDemandDatabase(with session: SessionIdEntity) -> Bool
    func sendExtensionsWithoutNoDStats()
}

public struct NodesOnDemandMigrationCheckerUseCase<T: MEGAClientRepositoryProtocol, U: StatsRepositoryProtocol>: NodesOnDemandMigrationCheckerUseCaseProtocol {
    
    private var megaclientRepository: T
    private var statsRepository: U
    
    public init(megaclientRepository: T, statsRepository: U) {
        self.megaclientRepository = megaclientRepository
        self.statsRepository = statsRepository
    }
    
    public func doesExistNodesOnDemandDatabase(with session: SessionIdEntity) -> Bool {
        megaclientRepository.doesExistNodesOnDemandDatabase(for: session)
    }
    
    public func sendExtensionsWithoutNoDStats() {
        statsRepository.sendStatsEvent(StatsEventEntity.extensionWithoutNoDDatabase)
    }
    
}
