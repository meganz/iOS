import MEGAAnalyticsDomain

public final class MockAnalyticsRepository: AnalyticsRepositoryProtocol {
    public static var newRepo: MockAnalyticsRepository {
        MockAnalyticsRepository()
    }
    
    public private(set) var sendAnalyticsEvent_Calls = [EventEntity]()
    
    public func sendAnalyticsEvent(_ eventEntity: EventEntity) {
        sendAnalyticsEvent_Calls.append(eventEntity)
    }
}
