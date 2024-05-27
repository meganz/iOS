import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

public protocol CurrentPlanDetailRouting: Routing {
    func dismiss()
}

public final class CurrentPlanDetailRouter: CurrentPlanDetailRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let accountDetails: AccountDetailsEntity
    private let assets: CurrentPlanDetailAssets
    
    public init(
        accountDetails: AccountDetailsEntity,
        assets: CurrentPlanDetailAssets,
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
        
        let viewModel = CurrentPlanDetailViewModel(
            currentPlanName: accountDetails.proLevel.toAccountTypeDisplayName(),
            currentPlanStorageUsed: String.memoryStyleString(fromByteCount: accountDetails.storageUsed),
            featureListHelper: featureListHelper,
            router: self
        )
        
        let hostingController = UIHostingController(
            rootView: CurrentPlanDetailView(viewModel: viewModel)
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
