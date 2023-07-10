public protocol AnalyticsUseCaseProtocol {
    func sendEvent(_ eventEntity: EventEntity)
}

public final class AnalyticsUseCase<
    T: AnalyticsRepositoryProtocol
>: AnalyticsUseCaseProtocol {
    
    private let analyticsRepo: T
    
    public init(analyticsRepo: T) {
        self.analyticsRepo = analyticsRepo
    }
    
    public func sendEvent(_ eventEntity: EventEntity) {
        analyticsRepo.sendAnalyticsEvent(eventEntity)
    }
}
