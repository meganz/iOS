
import Foundation

protocol AnalyticsUseCaseProtocol {
    func setAnalyticsEnabled(_ bool: Bool)
    func logEvent(_ name: AnalyticsEventEntity.Name, parameters: [AnalyticsEventEntity.Name : Any]?)
}

struct AnalyticsUseCase<T: AnalyticsRepositoryProtocol>: AnalyticsUseCaseProtocol {
    private let repository: T
    
    init(repository: T) {
        self.repository = repository
    }
    
    func setAnalyticsEnabled(_ bool: Bool) {
        repository.setAnalyticsEnabled(bool)
    }
    
    func logEvent(_ name: AnalyticsEventEntity.Name, parameters: [AnalyticsEventEntity.Name : Any]?) {
        repository.logEvent(name, parameters: parameters)
    }
}
