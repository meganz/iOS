import Foundation

final class MockStatsRepository: StatsRepositoryProtocol {
    static var newRepo: MockStatsRepository {
        MockStatsRepository()
    }
    
    var type: StatsEventEntity?
    
    func sendStatsEvent(_ type: StatsEventEntity) {
        self.type = type
    }
}
