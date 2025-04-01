import MEGAAnalyticsDomain
import MEGAAnalyticsiOS

final class EventSenderAdapter: EventSender, Sendable {
    private let analyticsUseCase: any AnalyticsUseCaseProtocol
    
    init(analyticsUseCase: some AnalyticsUseCaseProtocol) {
        self.analyticsUseCase = analyticsUseCase
    }
    
    func sendEvent(eventId: Int32, message: String, viewId: String?) {
        analyticsUseCase.sendEvent(
            EventEntity(
                id: EventID(eventId),
                message: message,
                viewId: viewId
            )
        )
    }
}
