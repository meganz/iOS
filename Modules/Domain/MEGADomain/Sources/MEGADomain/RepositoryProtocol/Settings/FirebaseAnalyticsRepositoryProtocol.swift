import Foundation

public protocol FirebaseAnalyticsRepositoryProtocol: RepositoryProtocol, Sendable {
    func setAnalyticsEnabled(_ enabled: Bool)
}
