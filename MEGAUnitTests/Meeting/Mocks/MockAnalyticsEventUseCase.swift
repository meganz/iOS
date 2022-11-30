@testable import MEGA
import MEGADomain

final class MockAnalyticsEventUseCase: AnalyticsEventUseCaseProtocol {
    func sendAnalyticsEvent(_ event: MEGADomain.AnalyticsEventEntity) { }
    
}
