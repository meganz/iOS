import MEGADomain

public protocol AnalyticsRepositoryProtocol: RepositoryProtocol {
    func sendAnalyticsEvent(_ eventEntity: EventEntity)
}
