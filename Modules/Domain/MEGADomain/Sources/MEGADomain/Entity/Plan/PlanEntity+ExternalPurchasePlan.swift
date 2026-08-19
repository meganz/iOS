public extension PlanEntity {
    var externalPurchasePath: String {
        switch type {
        case .proI: "propay_1"
        case .proII: "propay_2"
        case .proIII: "propay_3"
        case .lite: "propay_4"
        case .proFlexi: "propay_101"
        case .business: "registerb"
        default: "pro"
        }
    }
}
