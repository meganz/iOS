import Foundation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo
import UIKit

extension TransfersWidgetViewController: TransferWidgetResponderProtocol {
    private enum Constants {
        static let defaultBottomAnchor: CGFloat = -60
    }
    
    @objc
    func createTransfersWidgetViewModel() -> TransfersWidgetViewModel {
        TransfersWidgetViewModel(
            transfersListenerUseCase: TransfersListenerUseCase(
                repo: TransfersListenerRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            transfersInventoryUseCase: TransferInventoryUseCase(
                transferInventoryRepository: TransferInventoryRepository.newRepo,
                fileSystemRepository: FileSystemRepository.newRepo
            )
        )
    }
    
    @objc
    func openFolderNode(_ node: MEGANode, isFromViewInFolder: Bool) {
        guard let navigationController else { return }
        let nc = UINavigationController()
        let factory = CloudDriveViewControllerFactory.make(nc: nc)
        let vc = factory.buildBare(
            parentNode: node.toNodeEntity(),
            config: .init(
                displayMode: node.mnz_isInRubbishBin() && isFromViewInFolder ? .rubbishBin : .cloudDrive,
                isFromViewInFolder: isFromViewInFolder
            )
        )
        guard let vc else { return }
        
        navigationController.pushViewController(vc, animated: true)
    }
    
    @objc
    func configProgressIndicator() {
        let progressIndicatorView = ProgressIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        progressIndicatorView.isUserInteractionEnabled = true
        progressIndicatorView.isHidden = true
        
        self.progressView = progressIndicatorView
        
        progressIndicatorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapProgressView)))
        
        progressIndicatorView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragTransferWidget(_ :))))
    }
    
    @objc
    func setProgressViewInKeyWindow() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        showProgress(view: window, bottomAnchor: Constants.defaultBottomAnchor)
    }

    @objc
    func bringProgressToFrontKeyWindowIfNeeded() {
        guard let progressIndicatorView = TransfersWidgetViewController.sharedTransfer().progressView,
              let window = UIApplication.shared.keyWindow,
              progressIndicatorView.isDescendant(of: window) else {
                  return
              }
        window.bringSubviewToFront(progressIndicatorView)
    }
        
    @objc
    func showProgress(view: UIView, bottomAnchor: CGFloat) {
        guard let progressIndicatorView = TransfersWidgetViewController.sharedTransfer().progressView else { return }
        
        view.addSubview(progressIndicatorView)
        
        NSLayoutConstraint.deactivate([progressViewBottomConstraint, progressViewWidthConstraint, progressViewHeightConstraint, progressViewLeadingConstraint, progressViewTraillingConstraint])
        
        progressViewWidthConstraint = progressIndicatorView.widthAnchor.constraint(equalToConstant: 70.0)
        progressViewHeightConstraint = progressIndicatorView.heightAnchor.constraint(equalToConstant: 70)

        progressViewBottomConstraint = progressIndicatorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottomAnchor)
        progressViewLeadingConstraint = progressIndicatorView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 4.0)
        progressViewTraillingConstraint = progressIndicatorView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -4.0)
        
        let transferWidgetLeft = UserDefaults.standard.bool(forKey: "TransferWidgetViewLocationLeft")
        let transferWidgetSideConstraint: NSLayoutConstraint
        if transferWidgetLeft {
            transferWidgetSideConstraint = progressViewLeadingConstraint
        } else {
            transferWidgetSideConstraint = progressViewTraillingConstraint
        }
        
        NSLayoutConstraint.activate([progressViewWidthConstraint, progressViewHeightConstraint, progressViewBottomConstraint, transferWidgetSideConstraint])
    }
    
    @objc
    func showWidgetIfNeeded() {
        progressView?.showWidgetIfNeeded()
    }
    
    @objc
    func resetToKeyWindow() {
        setProgressViewInKeyWindow()
        bringProgressToFrontKeyWindowIfNeeded()
    }
    
    @objc
    func updateProgressView(bottomConstant: CGFloat) {
        progressViewBottomConstraint.constant = bottomConstant
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
    func pauseQueuedTransfers() {
        viewModel.pauseQueuedTransfers()
    }
    
    @objc
    func resumeQueuedTransfers() {
        viewModel.resumeQueuedTransfers()
    }
    
    // MARK: - Private
    
    @objc
    private func tapProgressView() {
        let transferWidgetVC = TransfersWidgetViewController.sharedTransfer()
        let navigationController = MEGANavigationController(rootViewController: transferWidgetVC)
        navigationController.addLeftDismissButton(withText: Strings.Localizable.close)
        CrashlyticsLogger.log(category: .transfersWidget, "Showing transfers widget from progress view")
        UIApplication.mnz_visibleViewController().present(navigationController, animated: true, completion: nil)
    }
    
    @objc
    private func dragTransferWidget(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let panView = panGestureRecognizer.view
        switch panGestureRecognizer.state {
        case .began, .changed:
            let translation = panGestureRecognizer.translation(in: panView)
            panGestureRecognizer.setTranslation(.zero, in: panView)
            guard let panViewCenterX = panView?.center.x,
                  let panViewCenterY = panView?.center.y else { return }
            panView?.center = CGPoint(x: panViewCenterX + translation.x, y: panViewCenterY + translation.y)
            
        case .ended, .cancelled:
            let location = panView?.center
            guard let x = location?.x else { return }
            
            if x > UIScreen.main.bounds.width / 2 {
                progressViewLeadingConstraint.isActive = false
                progressViewTraillingConstraint.isActive = true
                UserDefaults.standard.set(false, forKey: "TransferWidgetViewLocationLeft")
            } else {
                progressViewLeadingConstraint.isActive = true
                progressViewTraillingConstraint.isActive = false
                UserDefaults.standard.set(true, forKey: "TransferWidgetViewLocationLeft")
            }
            
            view.setNeedsLayout()
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
        default: break
        }
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
        // Active transfers include ongoing transfers and queued uploads
        transfers.count > 0 || queuedUploadTransfers.count > 0
    }
    
    @objc
    func hasCompletedTransfers() -> Bool {
        completedTransfers.count > 0
    }
    
    // MARK: - NavigationBarButtons
    @objc func updateNavBarButtonAppearance() {
        CrashlyticsLogger.log(category: .transfersWidget, "Updating Navigation bar button appearance. Navigation bar info: \(String(describing: navigationController?.navigationBar))")
        
        guard let nav = navigationController else { return }
        AppearanceManager.forceNavigationBarUpdate(nav.navigationBar, traitCollection: traitCollection)
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
    }
}

protocol TransferWidgetResponderProtocol: AnyObject {
    
    func setProgressViewInKeyWindow()
    
    func bringProgressToFrontKeyWindowIfNeeded()
    
    func updateProgressView(bottomConstant: CGFloat)
    
    func showWidgetIfNeeded()
}
