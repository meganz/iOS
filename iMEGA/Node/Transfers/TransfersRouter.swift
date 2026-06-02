import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Transfer
import UIKit

@MainActor
final class TransfersRouter {
    private weak var navigationController: UINavigationController?
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    init(
        navigationController: UINavigationController?,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.navigationController = navigationController
        self.featureFlagProvider = featureFlagProvider
    }

    func showTransfers() {
        let transferVC: UIViewController
        if featureFlagProvider.isFeatureFlagEnabled(for: .newTransfers) {
            transferVC = TransfersListViewControllerFactory.make(
                nodeUseCase: NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                )
            )
        } else {
            transferVC = UIStoryboard(name: "Transfers", bundle: nil)
                .instantiateViewController(withIdentifier: "TransfersWidgetViewControllerID")
        }
        transferVC.navigationItem.leftBarButtonItem = nil
        navigationController?.pushViewController(transferVC, animated: true)
    }
}
