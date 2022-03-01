
import Foundation
import FirebaseAnalytics

struct GoogleAnalyticsRepository: AnalyticsRepositoryProtocol {
    func setAnalyticsEnabled( _ bool: Bool) {
        Analytics.setAnalyticsCollectionEnabled(bool)
    }
    
    func logEvent(_ name: AnalayticsEventEntity.Name, parameters: [AnalayticsEventEntity.Name : Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
