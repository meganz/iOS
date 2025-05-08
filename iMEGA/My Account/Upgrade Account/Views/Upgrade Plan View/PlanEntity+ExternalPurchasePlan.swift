import MEGADomain

extension PlanEntity {
    var externalPurchasePath: String {
        switch type {
        case .proI: "propay_1"
        case .proII: "propay_2"
        case .proIII: "propay_3"
        case .lite: "propay_101"
        case .proFlexi: "propay_4"
        case .business: "registerb"
        default: "pro"
        }
    }
}
