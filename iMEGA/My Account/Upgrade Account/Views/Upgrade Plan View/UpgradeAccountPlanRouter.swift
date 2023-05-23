import MEGADomain
import MEGAData
import SwiftUI

final class UpgradeAccountPlanRouter: NSObject {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private var accountDetails: AccountDetailsEntity
    
    init(presenter: UIViewController, accountDetails: AccountDetailsEntity) {
        self.presenter = presenter
        self.accountDetails = accountDetails
    }
    
    func build() -> UIViewController {
        let viewModel = UpgradeAccountPlanViewModel(accountDetails: accountDetails,
                                                    purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo))
        let upgradeAccountPlanView = UpgradeAccountPlanView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: upgradeAccountPlanView)
        return hostingController
    }

    func start() {
        let viewController = build()
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
}
