public protocol SubscriptionRepositoryProtocol: RepositoryProtocol, Sendable {
    
    /// Cancel credit card or webclient subscriptions of the account and submit cancellation reason
    /// If used on an account with Apple or GooglePlay subscription, the subscription won't be cancelled but it will still submit the cancellation reason if supplied
    /// - Parameter reason: Reason for the cancellation. It can be nil.
    /// - Parameter subscriptionId: The subscription ID for the cancellation. It can be nil. Having a subscriptionId means cancelling one specific subscription. Nil subscriptionId means cancelling all subscriptions.
    /// - Parameter canContact: True if the user has permitted MEGA to contact them for the cancellation, otherwise false.
    /// - Throws: AccountErrorEntity.genericError
    func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws

    /// Cancel credit card or webclient subscriptions of the account and submit cancellation reason
    /// If used on an account with Apple or GooglePlay subscription, the subscription won't be cancelled but it will still submit the cancellation reason if supplied
    /// - Parameter reasonList: List of reasons chosen when canceling a subscription.
    /// - Parameter subscriptionId: The subscription ID for the cancellation. It can be nil. Having a subscriptionId means cancelling one specific subscription. Nil subscriptionId means cancelling all subscriptions.
    /// - Parameter canContact: True if the user has permitted MEGA to contact them for the cancellation, otherwise false.
    /// - Throws: AccountErrorEntity.genericError
    func cancelSubscriptions(reasonList: [CancelSubscriptionReasonEntity]?, subscriptionId: String?, canContact: Bool) async throws
}
