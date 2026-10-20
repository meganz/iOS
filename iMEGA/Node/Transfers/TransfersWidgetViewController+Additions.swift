import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGARepo
import MEGASwiftUI
import Transfer
import UIKit

extension TransfersWidgetViewController {
    @objc
    func createTransfersWidgetViewModel() -> TransfersWidgetViewModel {
        TransfersWidgetViewModel(
            transfersListenerUseCase: TransfersListenerUseCase(
                repo: TransfersListenerRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            transfersInventoryUseCase: TransferInventoryUseCase(
                transferInventoryRepository: TransferInventoryRepository.newRepo,
                fileSystemRepository: FileSystemRepository.sharedRepo
            ),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            router: NodeNavigationRouter()
        )
    }
    
    @objc
    func updateViewAppearance() {
        let backgroundColor = TokenColors.Background.page
        view.backgroundColor = backgroundColor
        tableView?.backgroundColor = backgroundColor
        tableView?.separatorStyle = .singleLine
        tableView?.separatorColor = TokenColors.Border.strong
    }
    
    @objc
    func configureLiquidGlassNavigationBar() {
        if #available(iOS 26.0, *) {
            setupLiquidGlassNavigationBar(with: TokenColors.Background.surface1)
        }
    }
    
    @objc
    func pauseQueuedTransfers() {
        viewModel.pauseQueuedTransfers()
    }
    
    @objc
    func resumeQueuedTransfers() {
        viewModel.resumeQueuedTransfers()
    }
    
    @objc
    func navigateToParentNode(_ node: MEGANode) {
        viewModel.navigateToParentNode(node.toNodeEntity())
    }
    
    @objc
    func fetchTransfers() -> [MEGATransfer] {
        transferInventoryUseCaseHelper
            .transfers()
            .toMEGATransfers(in: .shared)
    }

    @objc
    func fetchCompletedTransfers() -> [MEGATransfer] {
        transferInventoryUseCaseHelper.completedTransfers()
    }
    
    @objc
    func openOfflineFolder(path: String) {
        if let index = path.firstIndex(of: "/") {
            let pathFromOffline = String(path.suffix(from: index).dropFirst())
            let offlineVC: OfflineViewController = UIStoryboard(name: "Offline", bundle: nil).instantiateViewController(withIdentifier: "OfflineViewControllerID") as! OfflineViewController
            offlineVC.folderPathFromOffline = pathFromOffline.isEmpty ? nil : pathFromOffline
            navigationController?.pushViewController(offlineVC, animated: true)
        }
    }
    
    @objc
    func shouldShowTransferCancelledMessage(for transfer: MEGATransfer) -> Bool {
        let transferHasPrefix = transfer.path?.hasPrefix(FileManager.default.temporaryDirectory.path) ?? false

        return !transferHasPrefix || transfer.appData != nil
    }
    
    @objc
    func hasActiveTransfers() -> Bool {
        transfers.count > 0
    }
    
    @objc
    func hasCompletedTransfers() -> Bool {
        completedTransfers.count > 0
    }
    
    @objc
    func shouldShowViewInFolder(_ transfer: MEGATransfer) -> Bool {
        guard let appData = transfer.appData else { return true }
        return !(appData.contains(TransferMetaDataEntity.saveInPhotos.rawValue) || appData.contains(TransferMetaDataEntity.exportFile.rawValue))
    }
    
    @objc
    func makeTransferInventoryUseCaseHelper() -> TransferInventoryUseCaseHelper {
        TransferInventoryUseCaseHelper()
    }
    
    // MARK: - NavigationBarButtons

    @objc var isNewOfflineModeEnabled: Bool {
        DIContainer.featureFlagProvider.isNewOfflineModeEnabled
    }

    @objc func updateOfflineSnackBar() {
        guard isNewOfflineModeEnabled, view.window != nil else { return }

        if MEGAReachabilityManager.isReachable() {
            dismissSnackBar()
        } else {
            showSnackBar(
                snackBar: SnackBar(message: Strings.Localizable.Transfers.Snackbar.pausedAwaitingNetwork),
                displayDuration: OfflineSnackBar.displayDuration
            )
        }
    }

    @objc func updateNavBarButtonAppearance() {
        CrashlyticsLogger.log(category: .transfersWidget, "Updating Navigation bar button appearance. Navigation bar info: \(String(describing: navigationController?.navigationBar))")
        
        guard let nav = navigationController else { return }
        AppearanceManager.forceNavigationBarUpdate(nav.navigationBar)
    }
    
    // MARK: - Register TableViewCell Nibs
    @objc func registerNib(name: String, identifier: String) {
        let nib = UINib(nibName: name, bundle: nil)
        self.tableView?.register(nib, forCellReuseIdentifier: identifier)
    }
    
    // This overriden viewDidAppear is used for crash tracking purpose.
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CrashlyticsLogger.log(category: .transfersWidget, "Transfers widget did appear with navigation bar: \(String(describing: navigationController?.navigationBar))")
        updateOfflineSnackBar()
    }
}

// MARK: - BottomOverlayPresenterProtocol

extension TransfersWidgetViewController: BottomOverlayPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}

private enum OfflineSnackBar {
    /// Far beyond any session, so the snackbar never hides itself: only regaining the
    /// connection may take it away.
    static let displayDuration = TimeInterval(Int32.max)
}

// MARK: - SnackBarLayoutCustomizable

extension TransfersWidgetViewController: SnackBarLayoutCustomizable {
    /// Lifts the snackbar clear of the bottom toolbar, which carries Pause All / Clear All.
    /// The toolbar keeps its layout while hidden, so its height is only added when it shows.
    var additionalSnackBarBottomInset: CGFloat {
        guard let toolbar, !toolbar.isHidden else { return 0 }
        return toolbar.frame.height
    }

    @objc func applyToolbarHidden(_ hidden: Bool) {
        guard let toolbar, toolbar.isHidden != hidden else { return }

        toolbar.isHidden = hidden
        refreshSnackBarBottomInset(animated: true)
    }
}
