public enum AccountTypeEntity: CaseIterable, Sendable {
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
    public let storageUsed: Int64
    public let versionsStorageUsed: Int64
    public let storageMax: Int64
    public let transferOwnUsed: Int64
    public let transferMax: Int64
    public let proLevel: AccountTypeEntity
    public let proExpiration: Int
    public let subscriptionStatus: SubscriptionStatusEntity
    public let subscriptionRenewTime: Int
    public let subscriptionMethod: String?
    public let subscriptionCycle: SubscriptionCycleEntity
    public let numberUsageItems: Int
    
    public init(storageUsed: Int64, versionsStorageUsed: Int64, storageMax: Int64, transferOwnUsed: Int64, transferMax: Int64, proLevel: AccountTypeEntity, proExpiration: Int, subscriptionStatus: SubscriptionStatusEntity, subscriptionRenewTime: Int, subscriptionMethod: String?, subscriptionCycle: SubscriptionCycleEntity, numberUsageItems: Int) {
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
