import MEGAL10n
import SwiftUI

/// Presents the purchase confirmation / error alert driven by ``PlanPurchaseViewModel``.
///
/// Applied once per page so a purchase started from any button on that page surfaces the same alert.
private struct PlanPurchaseAlertModifier<ViewModel: PlanPurchaseAlertPresenting>: ViewModifier {
    @ObservedObject var viewModel: ViewModel

    func body(content: Content) -> some View {
        content.alert(item: $viewModel.presentedAlert, content: makeAlert)
    }

    private func makeAlert(_ alert: PlanPurchaseAlert) -> Alert {
        switch alert {
        case .failed:
            Alert(
                title: Text(Strings.Localizable.failedPurchaseTitle),
                message: Text(Strings.Localizable.failedPurchaseMessage),
                dismissButton: .default(Text(Strings.Localizable.ok))
            )
        case .websitePurchaseFailed:
            Alert(
                title: Text(Strings.Localizable.somethingWentWrong),
                dismissButton: .default(Text(Strings.Localizable.ok))
            )
        case .activeCancellableSubscription(let confirmCancelAndBuy):
            Alert(
                title: Text(Strings.Localizable.Account.Upgrade.AlreadyHaveASubscription.title),
                message: Text(Strings.Localizable.Account.Upgrade.AlreadyHaveACancellableSubscription.message),
                primaryButton: .default(Text(Strings.Localizable.yes)) {
                    Task { await confirmCancelAndBuy() }
                },
                secondaryButton: .cancel(Text(Strings.Localizable.no))
            )
        case .activeNonCancellableSubscription:
            Alert(
                title: Text(Strings.Localizable.Account.Upgrade.AlreadyHaveASubscription.title),
                message: Text(Strings.Localizable.Account.Upgrade.AlreadyHaveASubscription.message),
                dismissButton: .default(Text(Strings.Localizable.ok))
            )
        }
    }
}

public extension View {
    func planPurchaseAlert(_ viewModel: some PlanPurchaseAlertPresenting) -> some View {
        modifier(PlanPurchaseAlertModifier(viewModel: viewModel))
    }
}
