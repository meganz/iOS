import MEGADomain

public extension AccountDetailsEntity {
    init(
        storageUsed: Int64 = 0,
        versionsStorageUsed: Int64 = 0,
        storageMax: Int64 = 0,
        transferOwnUsed: Int64 = 0,
        transferMax: Int64 = 0,
        proLevel: AccountTypeEntity = .free,
        proExpiration: Int = 0,
        subscriptionStatus: SubscriptionStatusEntity = .none,
        subscriptionRenewTime: Int = 0,
        subscriptionMethod: String? = nil,
        subscriptionMethodId: PaymentMethodEntity = .none,
        subscriptionCycle: SubscriptionCycleEntity = .none,
        numberUsageItems: Int = 0,
        storageUsedForHandle: @escaping (@Sendable (_ handle: HandleEntity) -> Int64) = { _ in 0 },
        isTesting: Bool = true
    ) {
        self.init(
            storageUsed: storageUsed,
            versionsStorageUsed: versionsStorageUsed,
            storageMax: storageMax,
            transferOwnUsed: transferOwnUsed,
            transferMax: transferMax,
            proLevel: proLevel,
            proExpiration: proExpiration,
            subscriptionStatus: subscriptionStatus,
            subscriptionRenewTime: subscriptionRenewTime,
            subscriptionMethod: subscriptionMethod,
            subscriptionMethodId: subscriptionMethodId,
            subscriptionCycle: subscriptionCycle,
            numberUsageItems: numberUsageItems,
            storageUsedForHandle: storageUsedForHandle
        )
    }
    
    static var random: Self {
        .init(
            proLevel: AccountTypeEntity.allCases.randomElement() ?? .free
        )
    }
}
