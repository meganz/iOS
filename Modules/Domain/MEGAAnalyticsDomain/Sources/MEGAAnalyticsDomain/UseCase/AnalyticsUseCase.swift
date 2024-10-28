public protocol AnalyticsUseCaseProtocol: Sendable {
    func sendEvent(_ eventEntity: EventEntity)
}

public struct AnalyticsUseCase<
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
