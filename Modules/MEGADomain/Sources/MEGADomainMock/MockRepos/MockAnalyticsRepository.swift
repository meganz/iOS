import MEGADomain

public final class MockAnalyticsRepository: AnalyticsRepositoryProtocol {
    public static var newRepo: MockAnalyticsRepository {
        MockAnalyticsRepository()
    }
    
    public private(set) var type: AnalyticsEventEntity?
    
    public func sendAnalyticsEvent(_ type: AnalyticsEventEntity) {
        self.type = type
    }
}
