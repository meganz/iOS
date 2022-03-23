
@testable import MEGA

struct MockAnalyticsUseCase: AnalyticsUseCaseProtocol {
    func setAnalyticsEnabled(_ bool: Bool) {}
    
    func logEvent(_ name: AnalyticsEventEntity.Name, parameters: [AnalyticsEventEntity.Name : Any]?) {}
}
