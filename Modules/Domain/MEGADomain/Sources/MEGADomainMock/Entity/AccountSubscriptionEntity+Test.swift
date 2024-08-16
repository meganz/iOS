import MEGADomain

public extension AccountSubscriptionEntity {
    init(
        id: String? = nil,
        status: SubscriptionStatusEntity = .none,
        cycle: String? = nil,
        paymentMethod: String? = nil,
        paymentMethodId: PaymentMethodEntity = .none,
        renewTime: Int64 = 0,
        accountType: AccountTypeEntity = .free,
        features: [String]? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            id: id,
            status: status,
            cycle: cycle,
            paymentMethod: paymentMethod,
            paymentMethodId: paymentMethodId,
            renewTime: renewTime,
            accountType: accountType,
            features: features
        )
    }
}
