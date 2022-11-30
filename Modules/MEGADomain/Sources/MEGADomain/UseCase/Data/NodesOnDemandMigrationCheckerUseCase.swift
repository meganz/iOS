import Foundation

public typealias SessionIdEntity = String

public protocol NodesOnDemandMigrationCheckerUseCaseProtocol {
    func doesExistNodesOnDemandDatabase(with session: SessionIdEntity) -> Bool
    func sendExtensionsWithoutNoDStats()
}

public struct NodesOnDemandMigrationCheckerUseCase<T: MEGAClientRepositoryProtocol, U: AnalyticsEventUseCaseProtocol>: NodesOnDemandMigrationCheckerUseCaseProtocol {
    
    private var megaclientRepository: T
    private var analyticsEventUseCase: U
    
    public init(megaclientRepository: T, analyticsEventUseCase: U) {
        self.megaclientRepository = megaclientRepository
        self.analyticsEventUseCase = analyticsEventUseCase
    }
    
    public func doesExistNodesOnDemandDatabase(with session: SessionIdEntity) -> Bool {
        megaclientRepository.doesExistNodesOnDemandDatabase(for: session)
    }
    
    public func sendExtensionsWithoutNoDStats() {
        analyticsEventUseCase.sendAnalyticsEvent(.extensions(.withoutNoDDatabase))
    }
    
}
