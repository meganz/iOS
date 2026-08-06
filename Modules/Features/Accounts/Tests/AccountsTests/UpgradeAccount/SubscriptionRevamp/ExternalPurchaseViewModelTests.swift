@testable import Accounts
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import Testing

@MainActor
@Suite("ExternalPurchaseViewModel - buy on our website buttons")
struct ExternalPurchaseViewModelTests {

    // MARK: - buy

    @Test("Tapping a plan's button buys that plan on the website")
    func buy_withAKnownProductIdentifier_buysThatPlan() async {
        let (sut, purchaser) = makeSUT()

        await sut.buy(productIdentifier: "pro1.oneYear")

        #expect(purchaser.purchasedPlans.map(\.productIdentifier) == ["pro1.oneYear"])
    }

    @Test("A product identifier no loaded plan matches is ignored")
    func buy_withAnUnknownProductIdentifier_doesNothing() async {
        let (sut, purchaser) = makeSUT()

        await sut.buy(productIdentifier: "pro99.oneYear")

        #expect(purchaser.purchasedPlans.isEmpty)
    }

    // MARK: - Busy state

    @Test("The buttons are idle until a purchase starts")
    func isPurchasing_beforeAnyPurchase_isFalse() {
        #expect(makeSUT().0.isPurchasing == false)
    }

    @Test("The buttons are disabled while the link is being fetched")
    func isPurchasing_whilePurchasing_isTrue() {
        let (sut, purchaser) = makeSUT()

        purchaser.send(.purchasing)

        #expect(sut.isPurchasing)
    }

    @Test("The buttons come back once the browser has the purchase")
    func isPurchasing_whenHandedToTheBrowser_isFalse() async throws {
        let (sut, purchaser) = makeSUT()

        await sut.buy(productIdentifier: "pro1.oneYear")
        purchaser.send(.purchasing)
        let handOffToBrowser = try #require(purchaser.onWebsiteOpened)
        handOffToBrowser()

        #expect(sut.isPurchasing == false)
    }

    @Test("Every outcome that ends the attempt frees the buttons", arguments: [
        PlanPurchaseOutcome.succeeded,
        .failed,
        .cancelled,
        .cannotPurchaseWithActiveSubscription
    ])
    func isPurchasing_afterAFinalOutcome_isFalse(outcome: PlanPurchaseOutcome) {
        let (sut, purchaser) = makeSUT()

        purchaser.send(.purchasing)
        purchaser.send(outcome)

        #expect(sut.isPurchasing == false)
    }

    // MARK: - Alerts

    @Test("A blocked account raises the same alert the in-app route raises")
    func presentedAlert_whenBlocked_isTheActiveSubscriptionAlert() {
        let (sut, purchaser) = makeSUT()

        purchaser.send(.cannotPurchaseWithActiveSubscription)

        #expect(sut.presentedAlert?.id == PlanPurchaseAlert.activeNonCancellableSubscription.id)
    }

    @Test("A cancellable subscription offers to cancel and continue")
    func presentedAlert_whenCancellable_offersToCancelAndContinue() {
        let (sut, purchaser) = makeSUT()

        purchaser.send(.requiresCancellationConfirmation(confirmCancelAndBuy: {}))

        #expect(sut.presentedAlert?.id == PlanPurchaseAlert.activeCancellableSubscription(confirmCancelAndBuy: {}).id)
    }

    @Test("A failed purchase raises the website failure alert, not the App Store one")
    func presentedAlert_whenFailed_isTheWebsiteFailureAlert() {
        let (sut, purchaser) = makeSUT()

        purchaser.send(.failed)

        #expect(sut.presentedAlert?.id == PlanPurchaseAlert.websitePurchaseFailed.id)
    }

    @Test("Handing the purchase to the browser raises no alert")
    func presentedAlert_whenHandedToTheBrowser_isNil() async throws {
        let (sut, purchaser) = makeSUT()

        await sut.buy(productIdentifier: "pro1.oneYear")
        let handOffToBrowser = try #require(purchaser.onWebsiteOpened)
        handOffToBrowser()

        #expect(sut.presentedAlert == nil)
    }

    // MARK: - Completion

    @Test("A completed website purchase notifies the host once")
    func succeeded_notifiesTheHost() async {
        let purchaser = MockExternalPlanPurchasing()

        await confirmation("The host is notified of the purchase") { notified in
            let sut = ExternalPurchaseViewModel(
                purchaser: purchaser,
                plans: [plan()],
                onPurchased: { notified() }
            )
            withExtendedLifetime(sut) {
                purchaser.send(.succeeded)
            }
        }
    }

    // MARK: - SUT

    private func makeSUT() -> (ExternalPurchaseViewModel, MockExternalPlanPurchasing) {
        let purchaser = MockExternalPlanPurchasing()
        let sut = ExternalPurchaseViewModel(
            purchaser: purchaser,
            plans: [plan()],
            onPurchased: {}
        )
        return (sut, purchaser)
    }

    private func plan() -> PlanEntity {
        PlanEntity(
            productIdentifier: "pro1.oneYear",
            type: .proI,
            subscriptionCycle: .yearly,
            apiPrice: PlanPriceEntity(price: 9, formattedPrice: "$9.00", currency: "USD")
        )
    }
}
