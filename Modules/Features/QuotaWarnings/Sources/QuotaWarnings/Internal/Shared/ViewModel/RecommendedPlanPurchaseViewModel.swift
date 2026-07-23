import Combine
import MEGAAppPresentation
import MEGADomain
import SwiftUI

@MainActor
final class RecommendedPlanPurchaseViewModel: ObservableObject {
    /// Alert the footer presents in reaction to a purchase attempt.
    enum PurchaseAlert: Identifiable {
        case failed
        case activeCancellableSubscription(confirmCancelAndBuy: @MainActor () async -> Void)
        case activeNonCancellableSubscription

        var id: String {
            switch self {
            case .failed: "failed"
            case .activeCancellableSubscription: "activeCancellableSubscription"
            case .activeNonCancellableSubscription: "activeNonCancellableSubscription"
            }
        }
    }

    @Published var isPurchasing = false
    @Published var presentedAlert: PurchaseAlert?

    private let planPurchaser: any PlanPurchasing
    private let onPurchased: @MainActor () -> Void
    private var subscriptions = Set<AnyCancellable>()

    init(
        planPurchaser: any PlanPurchasing,
        onPurchased: @escaping @MainActor () -> Void
    ) {
        self.planPurchaser = planPurchaser
        self.onPurchased = onPurchased
        observeOutcomes()
    }

    func purchase(productIdentifier: String) async {
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
