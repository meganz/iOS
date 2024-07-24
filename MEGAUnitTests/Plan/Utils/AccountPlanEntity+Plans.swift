@testable import MEGA
import MEGADomain

public extension PlanEntity {
    static var freePlan = PlanEntity(type: .free, name: "Free")
    static var proLite_monthly = PlanEntity(type: .lite, name: "Pro lite", subscriptionCycle: .monthly, price: 1)
    static var proLite_yearly = PlanEntity(type: .lite, name: "Pro lite", subscriptionCycle: .yearly, price: 1)
    static var proI_monthly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly, price: 2)
    static var proI_yearly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly, price: 3)
    static var proII_monthly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly, price: 4)
    static var proII_yearly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly, price: 5)
    static var proIII_monthly = PlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly, price: 6)
    static var proIII_yearly = PlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .yearly, price: 7)
}
