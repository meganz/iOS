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
            subscriptionCycle: self.subscriptionCycle,
            numberUsageItems: self.numberUsageItems
        )
    }
}
