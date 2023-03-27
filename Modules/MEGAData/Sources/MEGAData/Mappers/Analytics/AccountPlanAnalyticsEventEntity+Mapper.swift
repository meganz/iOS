import MEGADomain

extension AccountPlanAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        get {
            var value: Int
            switch self {
            case .tapAccountPlanFreePlan: value = 99321
            case .tapAccountPlanProLite: value = 99322
            case .tapAccountPlanProI: value = 99323
            case .tapAccountPlanProII: value = 99324
            case .tapAccountPlanProIII: value = 99325
            }
            return value
        }
    }
    
    var description: String {
        get {
            var value: String
            switch self {
            case .tapAccountPlanFreePlan: value = "Tapped Account Plan Free plan"
            case .tapAccountPlanProLite: value = "Tapped Account Plan Pro Lite"
            case .tapAccountPlanProI: value = "Tapped Account Plan Pro I"
            case .tapAccountPlanProII: value = "Tapped Account Plan Pro II"
            case .tapAccountPlanProIII: value = "Tapped Account Plan Pro III"
            }
            return value
        }
    }
}
