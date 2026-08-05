import Combine
import Foundation
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("PlanPurchaser")
struct PlanPurchaseControllerTests {
    private typealias ResultSubject = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>

    /// StoreKit `SKError.Code.paymentCancelled` raw value.
    private static let cancelledErrorCode = 2

    private func makeSUT(
        currentAccountDetails: AccountDetailsEntity? = nil,
        refreshedAccountDetails: AccountDetailsEntity? = nil,
        resultSubject: ResultSubject = ResultSubject(),
        cancelResult: Result<Void, AccountErrorEntity> = .success(()),
        postPurchaseDelay: TimeInterval = 0
    ) -> (PlanPurchaser, MockAccountPlanPurchaseUseCase, MockSubscriptionsUseCase) {
        let purchaseUseCase = MockAccountPlanPurchaseUseCase(purchasePlanResultPublisher: resultSubject)
        let subscriptionsUseCase = MockSubscriptionsUseCase(requestResult: cancelResult)
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: currentAccountDetails,
            accountDetailsResult: refreshedAccountDetails.map { .success($0) } ?? .failure(.generic)
        )
        let sut = PlanPurchaser(
            purchaseUseCase: purchaseUseCase,
            eligibilityChecker: PlanPurchaseEligibilityChecker(
                subscriptionsUseCase: subscriptionsUseCase,
                accountUseCase: accountUseCase
            ),
            tracker: MockTracker(),
            postPurchaseDelay: postPurchaseDelay
        )
        return (sut, purchaseUseCase, subscriptionsUseCase)
    }

    private func collect(_ controller: PlanPurchaser, into buffer: OutcomeBuffer) -> AnyCancellable {
        controller.outcomes.sink { buffer.append($0) }
    }

    private nonisolated func details(method: PaymentMethodEntity) -> AccountDetailsEntity {
        .build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: method)
    }

    // MARK: - Decision (synchronous)

    @Test("Purchasable account starts the StoreKit purchase")
    func purchasable_startsPurchase() async {
        let (sut, purchaseUseCase, _) = makeSUT()
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")

        #expect(purchaseUseCase.registerPurchaseDelegateCalled == 1)
        #expect(purchaseUseCase.purchasePlanCalled == 1)
        #expect(buffer.containsPurchasing)
        token.cancel()
    }

    @Test("Cancellable subscription asks for cancellation confirmation instead of purchasing")
    func cancellable_requiresCancellationConfirmation() async {
        let (sut, purchaseUseCase, _) = makeSUT(currentAccountDetails: details(method: .stripe2))
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")

        #expect(purchaseUseCase.purchasePlanCalled == 0)
        #expect(buffer.containsCancellationConfirmation)
        token.cancel()
    }

    @Test("Non-cancellable subscription reports it can't purchase, without purchasing")
    func nonCancellable_cannotPurchase() async {
        let (sut, purchaseUseCase, _) = makeSUT(currentAccountDetails: details(method: .googleWallet))
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")

        #expect(purchaseUseCase.purchasePlanCalled == 0)
        #expect(buffer.containsCannotPurchaseWithActiveSubscription)
        token.cancel()
    }

    // MARK: - Result handling (async via publisher)

    @Test("Success posts side effects and emits succeeded")
    func success_emitsSucceeded() async {
        let subject = ResultSubject()
        let (sut, purchaseUseCase, _) = makeSUT(resultSubject: subject)
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")
        let terminal = await buffer.waitForTerminal { subject.send(.success(())) }

        #expect(terminal.isSucceeded)
        #expect(purchaseUseCase.startMonitoringSubmitReceiptAfterPurchaseCalled == 1)
        token.cancel()
    }

    @Test("Genuine failure emits failed")
    func failure_emitsFailed() async {
        let subject = ResultSubject()
        let (sut, _, _) = makeSUT(resultSubject: subject)
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")
        let terminal = await buffer.waitForTerminal {
            subject.send(.failure(AccountPlanErrorEntity(errorCode: 0, errorMessage: nil)))
        }

        #expect(terminal.isFailed)
        token.cancel()
    }

    @Test("User cancellation emits cancelled, not failed")
    func cancellation_emitsCancelled() async {
        let subject = ResultSubject()
        let (sut, _, _) = makeSUT(resultSubject: subject)
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")
        let terminal = await buffer.waitForTerminal {
            subject.send(.failure(AccountPlanErrorEntity(errorCode: Self.cancelledErrorCode, errorMessage: nil)))
        }

        #expect(terminal.isCancelled)
        token.cancel()
    }

    // MARK: - Cancel-then-buy (second span)

    @Test("Cancel-then-buy: cancel succeeds and account clears → proceeds to StoreKit purchase")
    func cancelThenBuy_proceedsWhenCleared() async throws {
        let (sut, purchaseUseCase, subscriptionsUseCase) = makeSUT(
            currentAccountDetails: details(method: .stripe2),      // → decision
            refreshedAccountDetails: details(method: .itunes)      // refresh shows no web sub → purchasable
        )
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")
        let confirm = try #require(buffer.cancellationConfirmationAction)
        await confirm()

        #expect(subscriptionsUseCase.cancelSubscriptionsWithReasonString_calledTimes == 1)
        #expect(purchaseUseCase.purchasePlanCalled == 1)
        token.cancel()
    }

    @Test("Cancel-then-buy: cancel fails → emits failed, no purchase")
    func cancelThenBuy_failsWhenCancelFails() async throws {
        let (sut, purchaseUseCase, _) = makeSUT(
            currentAccountDetails: details(method: .stripe2),
            cancelResult: .failure(.generic)
        )
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")
        let confirm = try #require(buffer.cancellationConfirmationAction)
        await confirm()

        #expect(purchaseUseCase.purchasePlanCalled == 0)
        #expect(buffer.containsFailed)
        token.cancel()
    }

    @Test("Cancel-then-buy: still blocked after cancel → emits failed, no purchase")
    func cancelThenBuy_failsWhenStillBlocked() async throws {
        let (sut, purchaseUseCase, _) = makeSUT(
            currentAccountDetails: details(method: .stripe2),
            refreshedAccountDetails: details(method: .stripe2)     // refresh still shows a web sub
        )
        let buffer = OutcomeBuffer()
        let token = collect(sut, into: buffer)

        await sut.purchase(productIdentifier: "pro1.yearly")
        let confirm = try #require(buffer.cancellationConfirmationAction)
        await confirm()

        #expect(purchaseUseCase.purchasePlanCalled == 0)
        #expect(buffer.containsFailed)
        token.cancel()
    }
}

/// Collects outcomes on the main actor and lets a test await the first non-`.purchasing` (terminal or
/// decision) outcome.
@MainActor
private final class OutcomeBuffer {
    private var outcomes: [PlanPurchaseOutcome] = []
    private var terminalContinuation: CheckedContinuation<PlanPurchaseOutcome, Never>?

    func append(_ outcome: PlanPurchaseOutcome) {
        outcomes.append(outcome)
        if case .purchasing = outcome { return }
        terminalContinuation?.resume(returning: outcome)
        terminalContinuation = nil
    }

    var containsPurchasing: Bool {
        outcomes.contains { if case .purchasing = $0 { true } else { false } }
    }

    var containsCancellationConfirmation: Bool {
        outcomes.contains { if case .requiresCancellationConfirmation = $0 { true } else { false } }
    }

    var containsCannotPurchaseWithActiveSubscription: Bool {
        outcomes.contains { if case .cannotPurchaseWithActiveSubscription = $0 { true } else { false } }
    }

    /// The `confirmCancelAndBuy` action carried by `.requiresCancellationConfirmation`, if one was emitted.
    var cancellationConfirmationAction: (@MainActor () async -> Void)? {
        for outcome in outcomes {
            if case .requiresCancellationConfirmation(let confirm) = outcome { return confirm }
        }
        return nil
    }

    var containsFailed: Bool {
        outcomes.contains { if case .failed = $0 { true } else { false } }
    }

    func waitForTerminal(_ trigger: () -> Void) async -> PlanPurchaseOutcome {
        await withCheckedContinuation { continuation in
            terminalContinuation = continuation
            trigger()
        }
    }
}

private extension PlanPurchaseOutcome {
    var isSucceeded: Bool { if case .succeeded = self { true } else { false } }
    var isFailed: Bool { if case .failed = self { true } else { false } }
    var isCancelled: Bool { if case .cancelled = self { true } else { false } }
}
