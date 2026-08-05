import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

@MainActor
@Suite("PlanPurchaseViewModel")
struct PlanPurchaseViewModelTests {

    // MARK: - purchase

    @Test("Purchasing marks the page busy and forwards the product identifier")
    func purchase_forwardsProductIdentifierAndMarksBusy() async {
        let (sut, purchaser, _) = makeSUT()

        await sut.purchase(productIdentifier: "pro1.oneYear")

        #expect(sut.isPurchasing)
        #expect(purchaser.purchasedProductIdentifiers == ["pro1.oneYear"])
    }

    // MARK: - Outcomes

    @Test("The purchasing outcome keeps the page busy")
    func purchasingOutcome_marksBusy() {
        let (sut, purchaser, _) = makeSUT()

        purchaser.send(.purchasing)

        #expect(sut.isPurchasing)
        #expect(sut.presentedAlert == nil)
    }

    @Test("A successful purchase clears the busy state and reports back once")
    func succeededOutcome_reportsPurchased() {
        let (sut, purchaser, recorder) = makeSUT()
        purchaser.send(.purchasing)

        purchaser.send(.succeeded)

        #expect(sut.isPurchasing == false)
        #expect(sut.presentedAlert == nil)
        #expect(recorder.purchasedCount == 1)
    }

    @Test("A failed purchase clears the busy state and presents the failure alert")
    func failedOutcome_presentsFailureAlert() {
        let (sut, purchaser, recorder) = makeSUT()
        purchaser.send(.purchasing)

        purchaser.send(.failed)

        #expect(sut.isPurchasing == false)
        #expect(sut.presentedAlert?.id == "failed")
        #expect(recorder.purchasedCount == 0)
    }

    @Test("A user-cancelled purchase clears the busy state without an alert")
    func cancelledOutcome_presentsNoAlert() {
        let (sut, purchaser, recorder) = makeSUT()
        purchaser.send(.purchasing)

        purchaser.send(.cancelled)

        #expect(sut.isPurchasing == false)
        #expect(sut.presentedAlert == nil)
        #expect(recorder.purchasedCount == 0)
    }

    @Test("A non-cancellable active subscription presents the blocking alert")
    func cannotPurchaseOutcome_presentsNonCancellableAlert() {
        let (sut, purchaser, _) = makeSUT()
        purchaser.send(.purchasing)

        purchaser.send(.cannotPurchaseWithActiveSubscription)

        #expect(sut.isPurchasing == false)
        #expect(sut.presentedAlert?.id == "activeNonCancellableSubscription")
    }

    @Test("A cancellable active subscription presents the confirmation alert")
    func requiresConfirmationOutcome_presentsCancellableAlert() {
        let (sut, purchaser, _) = makeSUT()
        purchaser.send(.purchasing)

        purchaser.send(.requiresCancellationConfirmation(confirmCancelAndBuy: {}))

        #expect(sut.isPurchasing == false)
        #expect(sut.presentedAlert?.id == "activeCancellableSubscription")
    }

    @Test("Confirming the cancellable-subscription alert runs the confirmation the purchaser supplied")
    func requiresConfirmationOutcome_confirmingRunsSuppliedClosure() async {
        let (sut, purchaser, recorder) = makeSUT()

        purchaser.send(.requiresCancellationConfirmation(confirmCancelAndBuy: { recorder.confirmedCount += 1 }))

        guard case let .activeCancellableSubscription(confirmCancelAndBuy) = sut.presentedAlert else {
            Issue.record("Expected the cancellable-subscription confirmation alert")
            return
        }
        await confirmCancelAndBuy()

        #expect(recorder.confirmedCount == 1)
    }

    // MARK: - Alert identity

    @Test("Each alert case has its own identifier")
    func purchaseAlert_identifiersAreDistinct() {
        let ids = Set(
            [
                PlanPurchaseAlert.failed,
                .websitePurchaseFailed,
                .activeCancellableSubscription(confirmCancelAndBuy: {}),
                .activeNonCancellableSubscription
            ].map(\.id)
        )

        #expect(ids.count == 4)
    }

    // MARK: - SUT

    private func makeSUT() -> (PlanPurchaseViewModel, MockPlanPurchasing, PurchaseRecorder) {
        let purchaser = MockPlanPurchasing()
        let recorder = PurchaseRecorder()
        let sut = PlanPurchaseViewModel(
            planPurchaser: purchaser,
            onPurchased: { recorder.purchasedCount += 1 }
        )
        return (sut, purchaser, recorder)
    }
}

// MARK: - Test doubles

@MainActor
private final class PurchaseRecorder {
    var purchasedCount = 0
    var confirmedCount = 0
}
