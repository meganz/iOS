import Foundation

public protocol MediaDiscoveryAnalyticsUseCaseProtocol {
    func sendPageStayStats(with duration: Int)
    func sendPageVisitedStats()
}

public struct MediaDiscoveryAnalyticsUseCase<T: AnalyticsRepositoryProtocol>: MediaDiscoveryAnalyticsUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func sendPageVisitedStats() {
        repo.sendAnalyticsEvent(.mediaDiscovery(.clickMediaDiscovery))
    }
    
    public func sendPageStayStats(with duration: Int) {
        guard duration > 10 else { return }
        
        let type = mediaDiscoveryStatsEventType(with: duration)
        
        repo.sendAnalyticsEvent(.mediaDiscovery(type))
    }
    
    // MARK: - Private
    
    private func mediaDiscoveryStatsEventType(with duration: Int) -> MediaDiscoveryAnalyticsEventEntity {
        var eventType = MediaDiscoveryAnalyticsEventEntity.stayOnMediaDiscoveryOver10s
        
        switch duration {
        case 10...30: eventType = MediaDiscoveryAnalyticsEventEntity.stayOnMediaDiscoveryOver10s
        case 30...60: eventType = MediaDiscoveryAnalyticsEventEntity.stayOnMediaDiscoveryOver30s
        case 60...180: eventType = MediaDiscoveryAnalyticsEventEntity.stayOnMediaDiscoveryOver60s
        default: eventType = MediaDiscoveryAnalyticsEventEntity.stayOnMediaDiscoveryOver180s
        }
        
        return eventType
    }
}
