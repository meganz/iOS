import MEGADomain

public final class MockAnalyticsEventUseCase: AnalyticsEventUseCaseProtocol {
    public private(set) var type: AnalyticsEventEntity?
    
    public init(type: AnalyticsEventEntity? = nil) {
        self.type = type
    }
    
    public func sendAnalyticsEvent(_ event: AnalyticsEventEntity) {
        self.type = event
    }
}
