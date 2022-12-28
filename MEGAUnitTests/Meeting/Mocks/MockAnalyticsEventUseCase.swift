@testable import MEGA
import MEGADomain

final class MockAnalyticsEventUseCase: AnalyticsEventUseCaseProtocol {
    public private(set) var type: AnalyticsEventEntity?
    
    func sendAnalyticsEvent(_ event: MEGADomain.AnalyticsEventEntity) {
        self.type = event
    }
}
