import MEGADomain

public struct MockSubscriptionsUsecase: SubscriptionsUsecaseProtocol {
    private let requestResult: Result<Void, AccountErrorEntity>
    
    public init(requestResult: Result<Void, AccountErrorEntity> = .failure(.generic)) {
        self.requestResult = requestResult
    }
    
    public func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws {
        try requestResult.get()
    }
}
