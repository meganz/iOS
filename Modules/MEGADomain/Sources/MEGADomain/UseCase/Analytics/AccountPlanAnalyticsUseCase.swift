import Foundation

public protocol AccountPlanAnalyticsUseCaseProtocol {
    func sendAccountPlanTapStats(plan: AccountTypeEntity)
}

public struct AccountPlanAnalyticsUseCase<T: AnalyticsRepositoryProtocol>: AccountPlanAnalyticsUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func sendAccountPlanTapStats(plan: AccountTypeEntity) {
        var eventType = AccountPlanAnalyticsEventEntity.tapAccountPlanFreePlan
        switch plan {
        case .free: eventType = .tapAccountPlanFreePlan
        case .lite: eventType = .tapAccountPlanProLite
        case .proI: eventType = .tapAccountPlanProI
        case .proII: eventType = .tapAccountPlanProII
        case .proIII: eventType = .tapAccountPlanProIII
        default: return
        }
        
        repo.sendAnalyticsEvent(.accountPlans(eventType))
    }
}
