import MEGADomain

public protocol AnalyticsRepositoryProtocol: RepositoryProtocol, Sendable {
    func sendAnalyticsEvent(_ eventEntity: MEGAAnalyticsDomain.EventEntity)
}
