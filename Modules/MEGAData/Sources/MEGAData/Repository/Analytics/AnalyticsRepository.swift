import MEGADomain
import MEGASdk

public struct AnalyticsRepository: AnalyticsRepositoryProtocol {
    public static var newRepo: AnalyticsRepository {
        AnalyticsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func sendAnalyticsEvent(_ event: AnalyticsEventEntity) {
        sdk.sendEvent(event.code, message: event.description)
    }
}
