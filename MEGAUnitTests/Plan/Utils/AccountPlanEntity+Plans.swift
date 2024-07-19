@testable import MEGA
import MEGADomain

public extension AccountPlanEntity {
    static var freePlan = AccountPlanEntity(type: .free, name: "Free")
    static var proLite_monthly = AccountPlanEntity(type: .lite, name: "Pro lite", subscriptionCycle: .monthly, price: 1)
    static var proLite_yearly = AccountPlanEntity(type: .lite, name: "Pro lite", subscriptionCycle: .yearly, price: 1)
    static var proI_monthly = AccountPlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly, price: 2)
    static var proI_yearly = AccountPlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly, price: 3)
    static var proII_monthly = AccountPlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly, price: 4)
    static var proII_yearly = AccountPlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly, price: 5)
    static var proIII_monthly = AccountPlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly, price: 6)
    static var proIII_yearly = AccountPlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .yearly, price: 7)
}
