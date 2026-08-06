import MEGAAppPresentation
import SwiftUI

/// Presents the website purchase alert, and does nothing when that route is unavailable.
///
/// The optional lives here rather than in ``PlanPurchaseAlertModifier`` because `@ObservedObject` cannot hold
/// one. Availability is resolved once per load and never flips, so the branch does not disturb view identity.
private struct ExternalPurchaseAlertModifier: ViewModifier {
    let viewModel: ExternalPurchaseViewModel?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let viewModel {
            content.planPurchaseAlert(viewModel)
        } else {
            content
        }
    }
}

extension View {
    func externalPurchaseAlert(_ viewModel: ExternalPurchaseViewModel?) -> some View {
        modifier(ExternalPurchaseAlertModifier(viewModel: viewModel))
    }
}
