import Combine

/// Drives a one-tap plan purchase and reports it through a single piece of state. Shared by the quota
/// dialog and the revamp subscription page so a purchase behaves the same wherever it is started.
/// It owns the busy flag that disables every buy button while a purchase is in flight and the alert
/// the host presents when a purchase needs confirmation or fails.
@MainActor
public final class PlanPurchaseViewModel: ObservableObject {
    /// Alert the host presents in reaction to a purchase attempt.
    public enum PurchaseAlert: Identifiable {
        case failed
        case activeCancellableSubscription(confirmCancelAndBuy: @MainActor () async -> Void)
        case activeNonCancellableSubscription

        public var id: String {
            switch self {
            case .failed: "failed"
            case .activeCancellableSubscription: "activeCancellableSubscription"
            case .activeNonCancellableSubscription: "activeNonCancellableSubscription"
            }
        }
    }

    @Published public private(set) var isPurchasing = false
    @Published public var presentedAlert: PurchaseAlert?

    private let planPurchaser: any PlanPurchasing
    private let onPurchased: @MainActor () -> Void
    private var subscriptions = Set<AnyCancellable>()

    public init(
        planPurchaser: any PlanPurchasing,
        onPurchased: @escaping @MainActor () -> Void
    ) {
        self.planPurchaser = planPurchaser
        self.onPurchased = onPurchased
        observeOutcomes()
    }

    public func purchase(productIdentifier: String) async {
        isPurchasing = true
        await planPurchaser.purchase(productIdentifier: productIdentifier)
    }

    private func observeOutcomes() {
        planPurchaser.outcomes
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
            presentedAlert = .failed
        case .cancelled:
            isPurchasing = false
            // legacy logic does nothing, so keep them consistent here.
        }
    }
}
