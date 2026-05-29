import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import SwiftUI
import UIKit

@MainActor
public enum TransfersListViewControllerFactory {
    public static func make() -> UIViewController {
        let inventoryUseCase = TransferInventoryUseCase(
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo
        )
        let counterUseCase = TransferCounterUseCase(
            repo: NodeTransferRepository.newRepo,
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo
        )
        let viewModel = TransfersListViewModel(
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase
        )
        let host = UIHostingController(rootView: TransfersListView(viewModel: viewModel))
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
