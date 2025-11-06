import MEGAAppPresentation
import SwiftUI

public protocol CancelSubscriptionStepsRouting: Routing {
    func dismiss()
}

public final class CancelSubscriptionStepsRouter: CancelSubscriptionStepsRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    private let type: SubscriptionType
    
    public init(
        type: SubscriptionType,
        presenter: UIViewController? = nil
    ) {
        self.presenter = presenter
        self.type = type
    }
    
    public func build() -> UIViewController {
        let helper = CancelSubscriptionStepsHelper(type: type)
        let viewModel = CancelSubscriptionStepsViewModel(helper: helper)
        
        let hostingController = UIHostingController(
            rootView: CancelSubscriptionStepsView(viewModel: viewModel)
        )
        
        baseViewController = hostingController
        return hostingController
    }
    
    public func start() {
        let viewController = build()
        presenter?.present(viewController, animated: true)
    }
    
    public func dismiss() {
        presenter?.dismiss(animated: true)
    }
}
