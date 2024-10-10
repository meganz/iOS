import MEGADomain

public final class MockSubscriptionsUseCase: SubscriptionsUseCaseProtocol, @unchecked Sendable {
    private let requestResult: Result<Void, AccountErrorEntity>
    public var cancelSubscriptions_calledTimes = 0
    
    public init(requestResult: Result<Void, AccountErrorEntity> = .failure(.generic)) {
        self.requestResult = requestResult
    }
    
    public func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws {
        cancelSubscriptions_calledTimes += 1
        try requestResult.get()
    }
}
