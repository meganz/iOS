import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

public protocol CancelAccountPlanRouting: Routing {
    func dismiss()
    func showCancellationSteps()
}

public final class CancelAccountPlanRouter: CancelAccountPlanRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let accountDetails: AccountDetailsEntity
    private let assets: CancelAccountPlanAssets
    
    public init(
        accountDetails: AccountDetailsEntity,
        assets: CancelAccountPlanAssets,
        presenter: UIViewController
    ) {
        self.accountDetails = accountDetails
        self.assets = assets
        self.presenter = presenter
    }
    
    public func build() -> UIViewController {
        let featureListHelper = FeatureListHelper(
            account: accountDetails,
            assets: assets
        )
        
        let viewModel = CancelAccountPlanViewModel(
            currentPlanName: accountDetails.proLevel.toAccountTypeDisplayName(),
            currentPlanStorageUsed: String.memoryStyleString(fromByteCount: accountDetails.storageUsed),
            featureListHelper: featureListHelper,
            router: self
        )
        
        let hostingController = UIHostingController(
            rootView: CancelAccountPlanView(viewModel: viewModel)
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
    
    public func showCancellationSteps() {
        switch accountDetails.subscriptionMethodId {
        case .itunes:
            // Apple
            break
        case .googleWallet:
            CancelSubscriptionStepsRouter(
                type: .google,
                presenter: baseViewController
            ).start()
        default:
            // Web client
            break
        }
    }
}
