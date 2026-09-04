import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Transfer
import UIKit

@MainActor
final class TransfersRouter {
    private weak var navigationController: UINavigationController?
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol

    init(
        navigationController: UINavigationController?,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) {
        self.navigationController = navigationController
        self.featureFlagProvider = featureFlagProvider
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }

    func showTransfers() {
        let transferVC: UIViewController
        if featureFlagProvider.isFeatureFlagEnabled(for: .newTransfers) || remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosTransfersRevamp) {
            let rowRouter = TransferRowActionRouter()
            transferVC = TransfersListViewControllerFactory.make(
                nodeUseCase: NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                ),
                rowRouter: rowRouter,
                featureFlagProvider: featureFlagProvider
            )
            // Transfers is pushed onto this nav controller; row actions push/present from it.
            rowRouter.navigationController = navigationController
        } else {
            transferVC = UIStoryboard(name: "Transfers", bundle: nil)
                .instantiateViewController(withIdentifier: "TransfersWidgetViewControllerID")
        }
        transferVC.navigationItem.leftBarButtonItem = nil
        navigationController?.pushViewController(transferVC, animated: true)
    }
}
