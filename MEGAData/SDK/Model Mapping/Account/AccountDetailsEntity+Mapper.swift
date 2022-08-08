import MEGADomain

extension AccountDetailsEntity {
    init(accountDetails: MEGAAccountDetails) {
        self.init(
            storageUsed: accountDetails.storageUsed?.uint64Value ?? 0,
            versionsStorageUsed: accountDetails.versionStorageUsed,
            storageMax: accountDetails.storageMax?.uint64Value ?? 0,
            transferOwnUsed: accountDetails.transferOwnUsed?.uint64Value ?? 0,
            transferMax: accountDetails.transferMax?.uint64Value ?? 0,
            proLevel: accountDetails.type.toAccountTypeEntity(),
            proExpiration: accountDetails.proExpiration,
            subscriptionStatus: accountDetails.subscriptionStatus.toSubscriptionStatusEntity(),
            subscriptionRenewTime: accountDetails.subscriptionRenewTime,
            subscriptionMethod: accountDetails.subscriptionMethod,
            subscriptionCycle: accountDetails.subscriptionCycle,
            numberUsageItems: accountDetails.numberUsageItems
        )
    }
}
