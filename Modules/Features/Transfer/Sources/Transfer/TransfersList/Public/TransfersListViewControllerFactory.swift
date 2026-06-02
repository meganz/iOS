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
        
        let viewModel = TransfersListViewModel(
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase,
            nodeUseCase: nodeUseCase,
            nodeAttributeUseCase: nodeAttributeUseCase,
            transfersListenerUseCase: transfersListenerUseCase
        )
        let host = UIHostingController(rootView: TransfersListView(viewModel: viewModel))
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
