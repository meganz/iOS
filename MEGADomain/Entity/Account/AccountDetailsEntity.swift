enum AccountTypeEntity {
    case free
    case proI
    case proII
    case proIII
    case lite
    case business
}

enum SubscriptionStatusEntity {
    case none
    case valid
    case invalid
}

struct AccountDetailsEntity {
    let storageUsed: UInt64
    let versionsStorageUsed: Int64
    let storageMax: UInt64
    let transferOwnUsed: UInt64
    let transferMax: UInt64
    let proLevel: AccountTypeEntity
    let proExpiration: Int
    let subscriptionStatus: SubscriptionStatusEntity
    let subscriptionRenewTime: Int
    let subscriptionMethod: String?
    let subscriptionCycle: String?
    let numberUsageItems: Int
}
