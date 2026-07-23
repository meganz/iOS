#if DEBUG
import Combine
import Foundation
import MEGAAppPresentation

/// Minimal `PlanPurchasing` for SwiftUI previews: emits the happy-path outcome so the footer / dialog render
/// their post-tap state without StoreKit. The rich, scenario-scripting mock lives with the QA simulator.
@MainActor
final class PreviewPlanPurchasing: PlanPurchasing {
    private let subject = PassthroughSubject<PlanPurchaseOutcome, Never>()

    var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> { subject.eraseToAnyPublisher() }

    func purchase(productIdentifier: String) async {
        subject.send(.purchasing)
        subject.send(.succeeded)
    }
}
#endif
