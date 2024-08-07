import MEGADomain
import MEGASdk

extension MEGAAccountSubscription {
    public func toAccountSubscriptionEntity() -> AccountSubscriptionEntity {
        AccountSubscriptionEntity(
            id: subcriptionId,
            status: status.toSubscriptionStatusEntity(),
            cycle: cycle,
            paymentMethod: paymentMethod,
            paymentMethodId: paymentMethodId.toPaymentMethodEntity(),
            renewTime: renewTime,
            accountType: accountType.toAccountTypeEntity(),
            features: features
        )
    }
}

extension Array where Element == MEGAAccountSubscription {
    public func toAccountSubscriptionEntityArray() -> [AccountSubscriptionEntity] {
        map {$0.toAccountSubscriptionEntity()}
    }
}
