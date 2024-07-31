import MEGADomain

public extension AccountDetailsEntity {
    static func build(
        storageUsed: Int64 = 0,
        versionsStorageUsed: Int64 = 0,
        storageMax: Int64 = 0,
        transferUsed: Int64 = 0,
        transferMax: Int64 = 0,
        proLevel: AccountTypeEntity = .free,
        proExpiration: Int = 0,
        subscriptionStatus: SubscriptionStatusEntity = .none,
        subscriptionRenewTime: Int = 0,
        subscriptionMethod: String? = nil,
        subscriptionMethodId: PaymentMethodEntity = .none,
        subscriptionCycle: SubscriptionCycleEntity = .none,
        numberUsageItems: Int = 0,
        subscriptions: [AccountSubscriptionEntity] = [],
        plans: [AccountPlanEntity] = [],
        storageUsedForHandle: @escaping @Sendable (_ handle: HandleEntity) -> Int64 = { _ in 0 }
    ) -> AccountDetailsEntity {
        .init(
            storageUsed: storageUsed,
            versionsStorageUsed: versionsStorageUsed,
            storageMax: storageMax,
            transferUsed: transferUsed,
            transferMax: transferMax,
            proLevel: proLevel,
            proExpiration: proExpiration,
            subscriptionStatus: subscriptionStatus,
            subscriptionRenewTime: subscriptionRenewTime,
            subscriptionMethod: subscriptionMethod,
            subscriptionMethodId: subscriptionMethodId,
            subscriptionCycle: subscriptionCycle,
            numberUsageItems: numberUsageItems,
            subscriptions: subscriptions,
            plans: plans,
            storageUsedForHandle: storageUsedForHandle
        )
    }
    
    static var random: Self {
        AccountDetailsEntity.build(
            proLevel: AccountTypeEntity.allCases.randomElement() ?? .free
        )
    }
}
