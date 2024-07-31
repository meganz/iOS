public enum AccountTypeEntity: CaseIterable, Sendable {
    case free
    case proI
    case proII
    case proIII
    case lite
    case business
    case proFlexi
    case starter
    case basic
    case essential
    
    static let lowerTierPlans: [AccountTypeEntity] = [.starter, .basic, .essential]

    public var isLowerTierPlan: Bool {
        return AccountTypeEntity.lowerTierPlans.contains(self)
    }
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

public enum PaymentMethodEntity: Sendable, CaseIterable {
    case none
    case balance
    case paypal
    case itunes
    case googleWallet
    case bitcoin
    case unionPay
    case fortumo
    case stripe
    case creditCard
    case centili
    case paysafeCard
    case astropay
    case reserved
    case windowsStore
    case tpay
    case directReseller
    case ECP
    case sabadell
    case huaweiWallet
    case stripe2
    case wireTransfer
}

public struct AccountDetailsEntity: Sendable {
    public let storageUsed: Int64
    public let versionsStorageUsed: Int64
    public let storageMax: Int64
    public let transferUsed: Int64
    public let transferMax: Int64
    public let proLevel: AccountTypeEntity
    public let proExpiration: Int
    public let subscriptionStatus: SubscriptionStatusEntity
    public let subscriptionRenewTime: Int
    public let subscriptionMethod: String?
    public let subscriptionMethodId: PaymentMethodEntity
    public let subscriptionCycle: SubscriptionCycleEntity
    public let numberUsageItems: Int
    public let subscriptions: [AccountSubscriptionEntity]
    public let plans: [AccountPlanEntity]
    public let storageUsedForHandle: @Sendable (_ handle: HandleEntity) -> Int64
    
    public init(
        storageUsed: Int64,
        versionsStorageUsed: Int64,
        storageMax: Int64,
        transferUsed: Int64,
        transferMax: Int64,
        proLevel: AccountTypeEntity,
        proExpiration: Int,
        subscriptionStatus: SubscriptionStatusEntity,
        subscriptionRenewTime: Int,
        subscriptionMethod: String?,
        subscriptionMethodId: PaymentMethodEntity,
        subscriptionCycle: SubscriptionCycleEntity,
        numberUsageItems: Int,
        subscriptions: [AccountSubscriptionEntity],
        plans: [AccountPlanEntity],
        storageUsedForHandle: @escaping @Sendable (_ handle: HandleEntity) -> Int64
    ) {
        self.storageUsed = storageUsed
        self.versionsStorageUsed = versionsStorageUsed
        self.storageMax = storageMax
        self.transferUsed = transferUsed
        self.transferMax = transferMax
        self.proLevel = proLevel
        self.proExpiration = proExpiration
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionRenewTime = subscriptionRenewTime
        self.subscriptionMethod = subscriptionMethod
        self.subscriptionMethodId = subscriptionMethodId
        self.subscriptionCycle = subscriptionCycle
        self.numberUsageItems = numberUsageItems
        self.subscriptions = subscriptions
        self.plans = plans
        self.storageUsedForHandle = storageUsedForHandle
    }
}

extension AccountDetailsEntity: Equatable {
    public static func == (lhs: AccountDetailsEntity, rhs: AccountDetailsEntity) -> Bool {
        return lhs.proLevel == rhs.proLevel
    }
}
