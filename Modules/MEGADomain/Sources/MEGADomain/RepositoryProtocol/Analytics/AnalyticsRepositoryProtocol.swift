import Foundation

public protocol AnalyticsRepositoryProtocol: RepositoryProtocol {
    func sendAnalyticsEvent(_ event: AnalyticsEventEntity)
}
