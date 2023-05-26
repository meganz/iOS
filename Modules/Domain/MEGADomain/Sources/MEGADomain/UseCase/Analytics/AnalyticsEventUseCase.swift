
public protocol AnalyticsEventUseCaseProtocol {
    func sendAnalyticsEvent(_ event: AnalyticsEventEntity)
}

public struct AnalyticsEventUseCase<T: AnalyticsRepositoryProtocol>: AnalyticsEventUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func sendAnalyticsEvent(_ event: AnalyticsEventEntity) {
        repo.sendAnalyticsEvent(event)
    }
}
