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
        let completionRecorder = SharedTransferFinishRecorder.shared

        let clearTransfersUseCase = ClearTransfersUseCase(
            repo: ClearTransfersRepository.newRepo,
            finishDateProvider: completionRecorder
        )

        let registry = TransferRegistry(controlUseCase: DependencyInjection.transferControlUseCase)

        let dependency = TransferTabDependency(
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase,
            registry: registry,
            locationResolver: TransferLocationResolver(
                nodeUseCase: nodeUseCase,
                nodeAttributeUseCase: nodeAttributeUseCase
            ),
            finishDateProvider: completionRecorder,
            filteringUserTransfers: true,
            clearTransfersUseCase: clearTransfersUseCase
        )

        let viewModel = TransfersListViewModel(
            dependency: dependency,
            transferListUseCase: TransferListUseCase(transfersListenerUseCase: transfersListenerUseCase),
            monitorPresenceUseCase: MonitorTransferTabPresenceUseCase(
                inventoryUseCase: inventoryUseCase,
                counterUseCase: counterUseCase,
                clearTransfersUseCase: clearTransfersUseCase,
                filteringUserTransfers: true
            )
        )
        let host = UIHostingController(rootView: TransfersListView(viewModel: viewModel))
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
