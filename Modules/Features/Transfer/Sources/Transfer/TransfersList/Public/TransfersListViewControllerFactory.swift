import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import SwiftUI
import UIKit

@MainActor
public enum TransfersListViewControllerFactory {
    /// - Parameter nodeUseCase: supplied by the app composition root. The Completed
    ///   tab resolves an upload's destination cloud path through it, and its
    ///   `NodeValidationRepository` dependency is only constructible in the app
    ///   target, so it can't be built here.
    public static func make(nodeUseCase: some NodeUseCaseProtocol) -> UIViewController {
        let inventoryUseCase = TransferInventoryUseCase(
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo
        )
        let counterUseCase = TransferCounterUseCase(
            repo: NodeTransferRepository.newRepo,
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo
        )
        let nodeAttributeUseCase = NodeAttributeUseCase(repo: NodeAttributeRepository.newRepo)

        let transfersListenerUseCase = TransfersListenerUseCase(
            repo: TransfersListenerRepository.newRepo,
            preferenceUseCase: PreferenceUseCase.default
        )

        let dependency = TransferTabDependency(
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase,
            registry: TransferRegistry(),
            locationResolver: TransferLocationResolver(
                nodeUseCase: nodeUseCase,
                nodeAttributeUseCase: nodeAttributeUseCase
            ),
            filteringUserTransfers: true,
            clearTransfersUseCase: ClearTransfersUseCase(repo: ClearTransfersRepository.newRepo)
        )

        let viewModel = TransfersListViewModel(
            dependency: dependency,
            transferListUseCase: TransferListUseCase(
                inventoryUseCase: inventoryUseCase,
                transfersListenerUseCase: transfersListenerUseCase,
                filteringUserTransfers: true
            )
        )
        let host = UIHostingController(rootView: TransfersListView(viewModel: viewModel))
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
