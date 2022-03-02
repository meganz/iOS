
import Foundation
import FirebaseAnalytics

struct GoogleAnalyticsRepository: AnalyticsRepositoryProtocol {
    func setAnalyticsEnabled( _ bool: Bool) {
        Analytics.setAnalyticsCollectionEnabled(bool)
    }
    
    func logEvent(_ name: AnalyticsEventEntity.Name, parameters: [AnalyticsEventEntity.Name : Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
