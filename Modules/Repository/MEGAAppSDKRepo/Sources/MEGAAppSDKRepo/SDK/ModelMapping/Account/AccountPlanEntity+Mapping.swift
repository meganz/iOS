import MEGADomain
import MEGASdk

extension MEGAAccountPlan {
    public func toAccountPlanEntity() -> AccountPlanEntity {
        AccountPlanEntity(
            isProPlan: self.isProPlan,
            accountType: self.accountType.toAccountTypeEntity(),
            expirationTime: self.expirationTime,
            startTime: self.startTime,
            features: self.features,
            type: self.type,
            subscriptionId: self.subscriptionId
        )
    }
}

extension Array where Element == MEGAAccountPlan {
    public func toAccountPlanEntityArray() -> [AccountPlanEntity] {
        map {$0.toAccountPlanEntity()}
    }
}
