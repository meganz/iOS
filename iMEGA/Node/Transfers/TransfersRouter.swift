import UIKit

@MainActor
final class TransfersRouter {
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func showTransfers() {
        let transferVC = UIStoryboard(name: "Transfers", bundle: nil)
            .instantiateViewController(withIdentifier: "TransfersWidgetViewControllerID")
        transferVC.navigationItem.leftBarButtonItem = nil
        navigationController?.pushViewController(transferVC, animated: true)
    }
}
