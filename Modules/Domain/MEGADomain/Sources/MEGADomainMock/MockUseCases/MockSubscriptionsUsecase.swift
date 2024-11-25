import MEGADomain

public final class MockSubscriptionsUseCase: SubscriptionsUseCaseProtocol, @unchecked Sendable {
    private let requestResult: Result<Void, AccountErrorEntity>
    public private(set) var cancelSubscriptionsWithReasonString_calledTimes = 0
    public private(set) var cancelSubscriptionsWithReasonList_calledTimes = 0
    
    public init(requestResult: Result<Void, AccountErrorEntity> = .failure(.generic)) {
        self.requestResult = requestResult
    }
    
    public func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws {
        cancelSubscriptionsWithReasonString_calledTimes += 1
        try requestResult.get()
    }
    
    public func cancelSubscriptions(reasonList: [CancelSubscriptionReasonEntity]?, subscriptionId: String?, canContact: Bool) async throws {
        cancelSubscriptionsWithReasonList_calledTimes += 1
        try requestResult.get()
    }
}
