import MEGADomain

public extension AccountPlanEntity {
    init(
        isProPlan: Bool = true,
        accountType: AccountTypeEntity = .proI,
        expirationTime: Int64 = 0,
        features: [String]? = nil,
        type: Int32 = 0,
        subscriptionId: String? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            isProPlan: isProPlan,
            accountType: accountType,
            expirationTime: expirationTime,
            features: features,
            type: type,
            subscriptionId: subscriptionId
        )
    }
}
