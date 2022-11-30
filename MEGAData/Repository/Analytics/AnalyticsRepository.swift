import Foundation
import MEGADomain
import MEGAData

struct AnalyticsRepository: AnalyticsRepositoryProtocol {
    static var newRepo: AnalyticsRepository {
        AnalyticsRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func sendAnalyticsEvent(_ event: AnalyticsEventEntity) {
        sdk.sendEvent(event.code, message: event.description)
    }
}
