import MEGADomain

public struct MockSubscriptionRepository: SubscriptionRepositoryProtocol {
    public static var newRepo: MockSubscriptionRepository {
        MockSubscriptionRepository()
    }
    
    private let requestResult: Result<Void, AccountErrorEntity>
    
    public init(
        requestResult: Result<Void, AccountErrorEntity> = .failure(AccountErrorEntity.generic)
    ) {
        self.requestResult = requestResult
    }
    
    public func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws {
        try requestResult.get()
    }
    
    public func cancelSubscriptions(reasonList: [CancelSubscriptionReasonEntity]?, subscriptionId: String?, canContact: Bool) async throws {
        try requestResult.get()
    }
}
