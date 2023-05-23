import MEGADomain

extension AccountPlanAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .tapAccountPlanFreePlan: return 99321
        case .tapAccountPlanProLite: return 99322
        case .tapAccountPlanProI: return 99323
        case .tapAccountPlanProII: return 99324
        case .tapAccountPlanProIII: return 99325
        }
    }
    
    var description: String {
        switch self {
        case .tapAccountPlanFreePlan: return "Tapped Account Plan Free plan"
        case .tapAccountPlanProLite: return "Tapped Account Plan Pro Lite"
        case .tapAccountPlanProI: return "Tapped Account Plan Pro I"
        case .tapAccountPlanProII: return "Tapped Account Plan Pro II"
        case .tapAccountPlanProIII: return "Tapped Account Plan Pro III"
        }
    }
}
