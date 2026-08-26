import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAInfrastructure
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
    /// - Parameter rowRouter: app-implemented navigation for per-row actions (View in
    ///   folder, Open with, Share link, open file); none of those destinations are
    ///   constructible from this package, so the app injects the router.
    /// - Parameter featureFlagProvider: supplied by the app composition root, which owns
    ///   the build-configuration rules for local flags. Only `offlineMode` is read here,
    ///   and only to decide whether the screen shows its offline presentation.
    /// - Parameter onClose: modal presenters pass their dismissal here instead of
    ///   attaching a UIKit bar button, so the screen can render Close as a SwiftUI
    ///   toolbar item and hand that slot to select-all while selecting. Pass nil
    ///   when pushing, to keep the standard back button.
    public static func make(
        nodeUseCase: some NodeUseCaseProtocol,
        rowRouter: some TransferRowRouting,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        onClose: (@MainActor () -> Void)? = nil
    ) -> UIViewController {
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

        let registry = TransferRegistry(
            controlUseCase: DependencyInjection.transferControlUseCase,
            rowRouter: rowRouter,
            clearTransfersUseCase: clearTransfersUseCase,
            thumbnailLoader: TransferThumbnailLoader(
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
            )
        )

        let dependency = TransferTabDependency(
            itemsUseCase: MonitorTransferTabItemsUseCase(
                inventoryUseCase: inventoryUseCase,
                counterUseCase: counterUseCase,
                clearTransfersUseCase: clearTransfersUseCase,
                filteringUserTransfers: true
            ),
            registry: registry,
            locationResolver: TransferLocationResolver(
                nodeUseCase: nodeUseCase,
                nodeAttributeUseCase: nodeAttributeUseCase
            ),
            finishDateProvider: completionRecorder,
            rowRouter: rowRouter,
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
            ),
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            transferQuotaUseCase: TransferQuotaUseCase(
                accountRepository: AccountRepository.newRepo,
                nodeTransferRepository: NodeTransferRepository.newRepo
            ),
            transferControlUseCase: DependencyInjection.transferControlUseCase,
            hapticFeedbackUseCase: HapticFeedbackUseCase(),
            networkMonitorUseCase: DependencyInjection.networkMonitorUseCase,
            isNewOfflineModeEnabled: featureFlagProvider.isNewOfflineModeEnabled,
            onClose: onClose
        )
        let host = UIHostingController(rootView: TransfersListView(viewModel: viewModel))
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
