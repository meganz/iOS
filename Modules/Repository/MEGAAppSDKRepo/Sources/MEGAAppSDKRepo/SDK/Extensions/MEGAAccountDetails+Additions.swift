import MEGASdk

extension MEGAAccountDetails {
    /// Returns an array of MEGAAccountSubscription objects representing the user's subscriptions.
    public func userSubscriptions() -> [MEGAAccountSubscription] {
        MEGASdk.fetchItems(
            numberOfItems: numberOfSubscriptions,
            itemAtIndexClosure: subscription
        )
    }
    
    /// Returns an array of MEGAAccountPlan objects representing the user's plans.
    public func userPlans() -> [MEGAAccountPlan] {
        MEGASdk.fetchItems(
            numberOfItems: numberOfPlans,
            itemAtIndexClosure: plan
        )
    }
}
