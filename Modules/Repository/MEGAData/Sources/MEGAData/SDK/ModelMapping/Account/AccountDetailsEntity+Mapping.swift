import MEGADomain
import MEGASdk

extension MEGAAccountDetails {
    public func toAccountDetailsEntity() -> AccountDetailsEntity {
        AccountDetailsEntity(
            storageUsed: self.storageUsed?.uint64Value ?? 0,
            versionsStorageUsed: self.versionStorageUsed,
            storageMax: self.storageMax?.uint64Value ?? 0,
            transferOwnUsed: self.transferOwnUsed?.uint64Value ?? 0,
            transferMax: self.transferMax?.uint64Value ?? 0,
            proLevel: self.type.toAccountTypeEntity(),
            proExpiration: self.proExpiration,
            subscriptionStatus: self.subscriptionStatus.toSubscriptionStatusEntity(),
            subscriptionRenewTime: self.subscriptionRenewTime,
            subscriptionMethod: self.subscriptionMethod,
            subscriptionCycle: subscriptionCycle(),
            numberUsageItems: self.numberUsageItems
        )
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
