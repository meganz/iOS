import MEGADomain

public final class MockStatsRepository: StatsRepositoryProtocol {
    public static var newRepo: MockStatsRepository {
        MockStatsRepository()
    }
    
    public private(set) var type: StatsEventEntity?
    
    public func sendStatsEvent(_ type: StatsEventEntity) {
        self.type = type
    }
}
