import MEGAAnalyticsDomain
import MEGADomain
import MEGASdk

public struct AnalyticsRepository: MEGADomain.AnalyticsRepositoryProtocol, MEGAAnalyticsDomain.AnalyticsRepositoryProtocol {
    public static var newRepo: AnalyticsRepository {
        AnalyticsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func sendAnalyticsEvent(_ event: AnalyticsEventEntity) {
        sdk.sendEvent(event.code, message: event.description, addJourneyId: false, viewId: nil)
    }
    
    public func sendAnalyticsEvent(_ eventEntity: MEGAAnalyticsDomain.EventEntity) {
        sdk.sendEvent(eventEntity.id, message: eventEntity.message, addJourneyId: true, viewId: eventEntity.viewId)
    }
}
