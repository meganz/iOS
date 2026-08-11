import MEGAAppPresentation
import SwiftUI

/// Presents ``PromoLandingDialogView`` modally, for entry points that offer the promotion before the
/// offer has been resolved. The dialog opens on its skeleton and loads the offer itself.
@MainActor
public final class PromoLandingDialogRouter: Routing {
    private weak var presenter: UIViewController?
    private let checksForExpiry: Bool
    private let promotedPlanUseCase: any PromotedPlanUseCaseProtocol
    private let planPurchaser: any PlanPurchasing
    private let onPurchased: @MainActor () -> Void

    public init(
        presenter: UIViewController?,
        checksForExpiry: Bool = true,
        promotedPlanUseCase: some PromotedPlanUseCaseProtocol,
        planPurchaser: some PlanPurchasing,
        onPurchased: @escaping @MainActor () -> Void = {}
    ) {
        self.presenter = presenter
        self.checksForExpiry = checksForExpiry
        self.promotedPlanUseCase = promotedPlanUseCase
        self.planPurchaser = planPurchaser
        self.onPurchased = onPurchased
    }

    public func build() -> UIViewController {
        weak var presentedController: UIViewController?

        let view = PromoLandingDialogView(
            dependency: PromoLandingDialogDependency(
                checksForExpiry: checksForExpiry,
                promotedPlanUseCase: promotedPlanUseCase,
                planPurchaser: planPurchaser,
                dismissAction: { presentedController?.dismiss(animated: true) },
                onPurchased: onPurchased
            )
        )

        let hostingController = UIHostingController(rootView: view)
        presentedController = hostingController
        return hostingController
    }

    public func start() {
        presenter?.present(build(), animated: true)
    }
}
