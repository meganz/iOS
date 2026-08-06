import Combine
import MEGAAppPresentation
import MEGADomain

/// Drives the "buy on our website" buttons: the busy flag that disables them while a link is being fetched,
/// and the alert the host presents when the account blocks the purchase.
///
/// Deliberately separate from ``PlanPurchaseViewModel``'s busy flag: the two routes are independent, so a
/// website link request does not disable the in-app buy buttons, matching the legacy screen.
@MainActor
final class ExternalPurchaseViewModel: ObservableObject, PlanPurchaseAlertPresenting {
    /// Disables the "buy on our website" buttons while a link request is in flight, and guards against
    /// overlapping taps triggering duplicate requests.
    @Published private(set) var isPurchasing = false
    @Published var presentedAlert: PlanPurchaseAlert?

    private let purchaser: any ExternalPlanPurchasing
    private let plans: [PlanEntity]
    private let onPurchased: @MainActor () -> Void
    private var subscriptions = Set<AnyCancellable>()

    init(
        purchaser: some ExternalPlanPurchasing,
        plans: [PlanEntity],
        onPurchased: @escaping @MainActor () -> Void
    ) {
        self.purchaser = purchaser
        self.plans = plans
        self.onPurchased = onPurchased
        observeOutcomes()
    }

    /// Buys the plan matching `productIdentifier` on the website; no-ops when no such plan is loaded.
    func buy(productIdentifier: String) async {
        guard let plan = plans.first(where: { $0.productIdentifier == productIdentifier }) else { return }

        await purchaser.purchase(plan: plan) { [weak self] in
            // The browser has it now, so the buttons come back to life while it is completed there.
            self?.isPurchasing = false
        }
    }

    private func observeOutcomes() {
        purchaser.outcomes
            .sink { [weak self] outcome in self?.handle(outcome) }
            .store(in: &subscriptions)
    }

    private func handle(_ outcome: PlanPurchaseOutcome) {
        switch outcome {
        case .purchasing:
            isPurchasing = true
        case let .requiresCancellationConfirmation(confirmCancelAndBuy):
            isPurchasing = false
            presentedAlert = .activeCancellableSubscription(confirmCancelAndBuy: confirmCancelAndBuy)
        case .cannotPurchaseWithActiveSubscription:
            isPurchasing = false
            presentedAlert = .activeNonCancellableSubscription
        case .succeeded:
            isPurchasing = false
            onPurchased()
        case .failed:
            isPurchasing = false
            presentedAlert = .websitePurchaseFailed
        case .cancelled:
            isPurchasing = false
        }
    }
}
