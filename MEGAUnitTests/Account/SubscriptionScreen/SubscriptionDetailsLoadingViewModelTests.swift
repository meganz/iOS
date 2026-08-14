import Foundation
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("SubscriptionDetailsLoadingViewModel")
struct SubscriptionDetailsLoadingViewModelTests {

    @Test("routes to goPro with the account details already in memory")
    @MainActor
    func currentAccountDetailsAreAlreadyAvailable() async {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(currentAccountDetails: currentDetails)
        let pricingRequester = MockPricingRequester()
        let viewModel = makeSUT(accountUseCase: accountUseCase, pricingRequester: pricingRequester)

        let route = await viewModel.determineRoute()

        #expect(route == .goPro(currentDetails))
        #expect(accountUseCase.refreshAccountDetails_calledCount == 0)
        #expect(pricingRequester.requestPricingCalled == 1)
    }

    @Test("routes to goPro after fetching the account details")
    @MainActor
    func accountDetailsAreFetched() async {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(accountDetailsResult: .success(currentDetails))
        let pricingRequester = MockPricingRequester()
        let viewModel = makeSUT(accountUseCase: accountUseCase, pricingRequester: pricingRequester)

        let route = await viewModel.determineRoute()

        #expect(route == .goPro(currentDetails))
        #expect(accountUseCase.refreshAccountDetails_calledCount == 1)
        #expect(pricingRequester.requestPricingCalled == 1)
    }

    @Test("non free account dismisses without loading the products")
    @MainActor
    func nonFreeAccount() async {
        let accountUseCase = MockAccountUseCase(accountDetailsResult: .success(.build(proLevel: .proI)))
        let pricingRequester = MockPricingRequester()
        let viewModel = makeSUT(accountUseCase: accountUseCase, pricingRequester: pricingRequester)

        #expect(await viewModel.determineRoute() == .dismiss)
        #expect(pricingRequester.requestPricingCalled == 0)
    }

    @Test("dismisses without loading the products when the account details fail to load")
    @MainActor
    func failedToRetrieveAccount() async {
        let accountUseCase = MockAccountUseCase(accountDetailsResult: .failure(AccountDetailsErrorEntity.generic))
        let pricingRequester = MockPricingRequester()
        let viewModel = makeSUT(accountUseCase: accountUseCase, pricingRequester: pricingRequester)

        #expect(await viewModel.determineRoute() == .dismiss)
        #expect(pricingRequester.requestPricingCalled == 0)
    }

    /// Abandoning the wait still routes to goPro, matching the legacy behaviour of opening the
    /// upgrade screen with whatever products are loaded — including none.
    @Test("routes to goPro even when the pricing request is abandoned")
    @MainActor
    func pricingRequestThrows() async {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(currentAccountDetails: currentDetails)
        let viewModel = makeSUT(
            accountUseCase: accountUseCase,
            pricingRequester: MockPricingRequester(result: .failure(CancellationError()))
        )

        #expect(await viewModel.determineRoute() == .goPro(currentDetails))
    }

    /// The reason this screen exists: routing to the upgrade screen before the products are loaded
    /// is what shows an empty plan list.
    @Test("does not route to goPro until the products have loaded", .timeLimit(.minutes(1)))
    @MainActor
    func waitsForProductsBeforeRouting() async throws {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(currentAccountDetails: currentDetails)
        let pricingRequester = SuspendingPricingRequester()
        let viewModel = makeSUT(accountUseCase: accountUseCase, pricingRequester: pricingRequester)
        @Atomic var hasRouted = false

        let routeTask = Task {
            let route = await viewModel.determineRoute()
            $hasRouted.mutate { $0 = true }
            return route
        }

        // Once the requester holds a suspended caller, the view model is provably still waiting.
        try await waitUntil { pricingRequester.hasSuspendedCaller }
        #expect(hasRouted == false)

        pricingRequester.finishRequest()

        #expect(await routeTask.value == .goPro(currentDetails))
    }

    @MainActor
    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        pricingRequester: some PricingRequesting = MockPricingRequester()
    ) -> SubscriptionDetailsLoadingViewModel {
        SubscriptionDetailsLoadingViewModel(accountUseCase: accountUseCase, pricingRequester: pricingRequester)
    }
}

// MARK: - Helpers

/// Polls `condition` so tests never assume how quickly a task reaches its suspension point.
private func waitUntil(
    timeout: Duration = .seconds(5),
    _ condition: @Sendable () -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(5))
    }
    Issue.record("Timed out waiting for the expected condition")
}

/// Suspends its caller until the test releases it, so the test can observe the view model mid-wait.
private final class SuspendingPricingRequester: PricingRequesting, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?

    var hasSuspendedCaller: Bool {
        lock.withLock { continuation != nil }
    }

    func requestPricing() async throws {
        await withCheckedContinuation { continuation in
            lock.withLock { self.continuation = continuation }
        }
    }

    func refreshPricing() async throws {
        try await requestPricing()
    }

    func cancel() {}

    func finishRequest() {
        let continuation = lock.withLock {
            defer { self.continuation = nil }
            return self.continuation
        }
        continuation?.resume()
    }
}
