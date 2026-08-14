import MEGADomain
import MEGASwift

public final class MockPricingRequester: PricingRequesting, @unchecked Sendable {
    @Atomic public var requestPricingCalled = 0
    @Atomic public var refreshPricingCalled = 0
    @Atomic public var cancelCalled = 0

    private let result: Result<Void, any Error>

    public init(result: Result<Void, any Error> = .success(())) {
        self.result = result
    }

    public func requestPricing() async throws {
        $requestPricingCalled.mutate { $0 += 1 }
        try result.get()
    }

    public func refreshPricing() async throws {
        $refreshPricingCalled.mutate { $0 += 1 }
        try result.get()
    }

    public func cancel() {
        $cancelCalled.mutate { $0 += 1 }
    }
}
