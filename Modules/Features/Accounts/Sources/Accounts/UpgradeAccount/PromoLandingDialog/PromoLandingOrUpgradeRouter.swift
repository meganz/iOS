import MEGAAppPresentation
import MEGADomain
import SwiftUI

@MainActor
public final class PromoLandingOrUpgradeRouter {
    /// presenter needs to be a closure rather than a stored view controller because `start()` awaits the offer
    /// before presenting, and whatever was visible when the router was built may be gone by the time it returns.
    private let presenter: @MainActor () -> UIViewController?
    private let promotedPlanUseCase: any PromotedPlanUseCaseProtocol
    private let planPurchaser: any PlanPurchasing
    private let showUpgradeScreen: @MainActor () -> Void
    private let onPurchased: @MainActor () -> Void
    /// Whether the dialog may take over the screen right now, supplied by `PromoDialogInterruptibility` in the app target
    private let canInterruptUser: @MainActor () -> Bool

    public init(
        presenter: @escaping @MainActor () -> UIViewController?,
        promotedPlanUseCase: some PromotedPlanUseCaseProtocol,
        planPurchaser: some PlanPurchasing,
        showUpgradeScreen: @escaping @MainActor () -> Void,
        canInterruptUser: @escaping @MainActor () -> Bool = { true },
        onPurchased: @escaping @MainActor () -> Void = {}
    ) {
        self.presenter = presenter
        self.promotedPlanUseCase = promotedPlanUseCase
        self.planPurchaser = planPurchaser
        self.showUpgradeScreen = showUpgradeScreen
        self.canInterruptUser = canInterruptUser
        self.onPurchased = onPurchased
    }

    public func start() async {
        guard canInterruptUser() else { return }

        let fetchResult = try? await promotedPlanUseCase.fetchPromotedPlan(checksForExpiry: true)

        // A blocking screen may have taken over while the offer was resolving.
        guard canInterruptUser() else { return }

        guard let fetchResult else {
            showUpgradeScreen()
            return
        }

        presenter()?.present(build(for: fetchResult), animated: true)
    }

    private func build(for fetchResult: PromotedPlanFetchResult) -> UIViewController {
        weak var presentedController: UIViewController?

        let view = PromoLandingDialogContentView(
            dependency: PromoLandingDialogContentView.Dependency(
                fetchResult: fetchResult,
                planPurchaser: planPurchaser,
                dismissAction: { presentedController?.dismiss(animated: true) },
                onPurchased: onPurchased,
                // The upgrade page presents from whatever presented this dialog, so it waits for the dialog to close.
                viewAllPlansAction: { [showUpgradeScreen] in
                    presentedController?.dismiss(animated: true) { showUpgradeScreen() }
                }
            )
        )

        let hostingController = PromoDialogBlockingHostingController(rootView: view)
        presentedController = hostingController
        return hostingController
    }
}
