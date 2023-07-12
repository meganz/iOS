public enum AccountTypeEntity: Sendable {
    case free
    case proI
    case proII
    case proIII
    case lite
    case business
    case proFlexi
}

public enum SubscriptionStatusEntity: Sendable {
    case none
    case valid
    case invalid
}

public enum SubscriptionCycleEntity: Sendable {
    case none
    case monthly
    case yearly
}

public struct AccountDetailsEntity: Sendable {
    public let storageUsed: UInt64
    public let versionsStorageUsed: Int64
    public let storageMax: UInt64
    public let transferOwnUsed: UInt64
    public let transferMax: UInt64
    public let proLevel: AccountTypeEntity
    public let proExpiration: Int
    public let subscriptionStatus: SubscriptionStatusEntity
    public let subscriptionRenewTime: Int
    public let subscriptionMethod: String?
    public let subscriptionCycle: SubscriptionCycleEntity
    public let numberUsageItems: Int
    
    public init(storageUsed: UInt64, versionsStorageUsed: Int64, storageMax: UInt64, transferOwnUsed: UInt64, transferMax: UInt64, proLevel: AccountTypeEntity, proExpiration: Int, subscriptionStatus: SubscriptionStatusEntity, subscriptionRenewTime: Int, subscriptionMethod: String?, subscriptionCycle: SubscriptionCycleEntity, numberUsageItems: Int) {
        self.storageUsed = storageUsed
        self.versionsStorageUsed = versionsStorageUsed
        self.storageMax = storageMax
        self.transferOwnUsed = transferOwnUsed
        self.transferMax = transferMax
        self.proLevel = proLevel
        self.proExpiration = proExpiration
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionRenewTime = subscriptionRenewTime
        self.subscriptionMethod = subscriptionMethod
        self.subscriptionCycle = subscriptionCycle
        self.numberUsageItems = numberUsageItems
    }
}

extension AccountDetailsEntity: Equatable {
    public static func == (lhs: AccountDetailsEntity, rhs: AccountDetailsEntity) -> Bool {
        return lhs.proLevel == rhs.proLevel
    }
}
