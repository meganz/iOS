import MEGADomain
import MEGASdk

extension MEGAAccountSubscription {
    public func toAccountSubscriptionEntity() -> AccountSubscriptionEntity {
        AccountSubscriptionEntity(
            id: self.subcriptionId,
            status: self.status.toSubscriptionStatusEntity(),
            cycle: self.cycle,
            paymentMethod: self.paymentMethod,
            paymentMethodId: self.paymentMethodId,
            renewTime: self.renewTime,
            accountType: self.accountType.toAccountTypeEntity(),
            features: self.features
        )
    }
}

extension Array where Element == MEGAAccountSubscription {
    public func toAccountSubscriptionEntityArray() -> [AccountSubscriptionEntity] {
        map {$0.toAccountSubscriptionEntity()}
    }
}
