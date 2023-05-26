import MEGADomain

public extension AccountDetailsEntity {
    init(storageUsed: UInt64 = 0,
         versionsStorageUsed: Int64 = 0,
         storageMax: UInt64 = 0,
         transferOwnUsed: UInt64 = 0,
         transferMax: UInt64 = 0,
         proLevel: AccountTypeEntity = .free,
         proExpiration: Int = 0,
         subscriptionStatus: SubscriptionStatusEntity = .none,
         subscriptionRenewTime: Int = 0,
         subscriptionMethod: String? = nil,
         subscriptionCycle: String? = nil,
         numberUsageItems: Int = 0,
         isTesting: Bool = true) {
        self.init(storageUsed: storageUsed, versionsStorageUsed: versionsStorageUsed, storageMax: storageMax, transferOwnUsed: transferOwnUsed, transferMax: transferMax, proLevel: proLevel, proExpiration: proExpiration, subscriptionStatus: subscriptionStatus, subscriptionRenewTime: subscriptionRenewTime, subscriptionMethod: subscriptionMethod, subscriptionCycle: subscriptionCycle, numberUsageItems: numberUsageItems)
    }
}
