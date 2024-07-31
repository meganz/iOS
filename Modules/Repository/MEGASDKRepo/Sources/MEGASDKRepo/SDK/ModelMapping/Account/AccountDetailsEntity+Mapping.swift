import MEGADomain
import MEGASdk

extension MEGAAccountDetails {
    public func toAccountDetailsEntity() -> AccountDetailsEntity {
        AccountDetailsEntity(
            storageUsed: self.storageUsed,
            versionsStorageUsed: self.versionStorageUsed,
            storageMax: self.storageMax,
            transferUsed: self.transferUsed,
            transferMax: self.transferMax,
            proLevel: self.type.toAccountTypeEntity(),
            proExpiration: self.proExpiration,
            subscriptionStatus: self.subscriptionStatus.toSubscriptionStatusEntity(),
            subscriptionRenewTime: self.subscriptionRenewTime,
            subscriptionMethod: self.subscriptionMethod,
            subscriptionMethodId: self.subscriptionMethodId.toPaymentMethodEntity(),
            subscriptionCycle: self.subscriptionCycle(),
            numberUsageItems: self.numberUsageItems,
            subscriptions: userSubscriptions().toAccountSubscriptionEntityArray(),
            plans: userPlans().toAccountPlanEntityArray()
        ) { handle in
            self.storageUsed(forHandle: handle)
        }
    }
    
    private func subscriptionCycle() -> SubscriptionCycleEntity {
        guard let subscriptionCycle else { return .none }
        switch subscriptionCycle {
        case "1 Y": return .yearly
        case "1 M": return .monthly
        default: return .none
        }
    }
}
