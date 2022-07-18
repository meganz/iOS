import Foundation

protocol MediaDiscoveryStatsUseCaseProtocol {
    func sendPageStayStats(with duration: Int)
    func sendPageVisitedStats()
}

struct MediaDiscoveryStatsUseCase<T: StatsRepositoryProtocol>: MediaDiscoveryStatsUseCaseProtocol {
    private let repo: T
    
    init(repository: T) {
        repo = repository
    }
    
    func sendPageVisitedStats() {
        repo.sendStatsEvent(StatsEventEntity.clickMediaDiscovery)
    }
    
    func sendPageStayStats(with duration: Int) {
        guard duration > 10 else { return }
        
        let type = mediaDiscoveryStatsEventType(with: duration)
        
        repo.sendStatsEvent(type)
    }
    
    // MARK: - Private
    
    private func mediaDiscoveryStatsEventType(with duration: Int) -> StatsEventEntity {
        var eventType = StatsEventEntity.stayOnMediaDiscoveryOver10s
        
        switch duration {
        case 10...30: eventType = StatsEventEntity.stayOnMediaDiscoveryOver10s
        case 30...60: eventType = StatsEventEntity.stayOnMediaDiscoveryOver30s
        case 60...180: eventType = StatsEventEntity.stayOnMediaDiscoveryOver60s
        default: eventType = StatsEventEntity.stayOnMediaDiscoveryOver180s
        }
        
        return eventType
    }
}
