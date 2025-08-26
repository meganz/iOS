import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Notifications

extension NotificationsTableViewController {
    // MARK: - Register cell
    @objc func registerCustomCells() {
        tableView.register(HostingTableViewCell<NotificationItemView>.self,
                                 forCellReuseIdentifier: "NotificationItemView")
    }
    
    // MARK: - Promo cell
    @objc func promoCell(indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationItemView", for: indexPath) as? HostingTableViewCell<NotificationItemView> else {
            fatalError("Failed to load HostingTableViewCell<NotificationItemView>")
        }
        
        let promo = viewModel.promoList[indexPath.row]
        let promoView = NotificationItemView(
            viewModel:
                NotificationItemViewModel(
                    notification: promo,
                    imageLoader: viewModel.imageLoader
                )
        )
    
        cell.host(promoView, parent: self)
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - Contents
    @objc func contentForTakedownReinstatedNode(withHandle handle: HandleEntity, nodeFont: UIFont) -> NSAttributedString? {
        guard let node = MEGASdk.shared.node(forHandle: handle) else { return nil }
        let nodeName = node.name ?? ""
        switch node.type {
        case .file:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownReinstated.file(nodeName))
        case .folder:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownReinstated.folder(nodeName))
        default: return nil
        }
    }
    
    @objc func contentForTakedownPubliclySharedNode(withHandle handle: HandleEntity, nodeFont: UIFont) -> NSAttributedString? {
        guard let node = MEGASdk.shared.node(forHandle: handle) else { return nil }
        let nodeName = node.name ?? ""
        switch node.type {
        case .file:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownPubliclyShared.file(nodeName))
        case .folder:
            return contentMessageAttributedString(withNodeName: nodeName,
                                                  nodeFont: nodeFont,
                                                  message: Strings.Localizable.Notifications.Message.TakenDownPubliclyShared.folder(nodeName))
        default: return nil
        }
    }
    
    private func contentMessageAttributedString(withNodeName nodeName: String,
                                                nodeFont: UIFont,
                                                message: String) -> NSAttributedString? {
        let contentAttributedText = NSMutableAttributedString(string: message)
        if let nodeNameRange = message.range(of: nodeName) {
            contentAttributedText.addAttributes([.font: nodeFont], range: NSRange(nodeNameRange, in: message))
        }
        return contentAttributedText
    }
    
    @objc func logUserAlertsStatus(_ userAlerts: [MEGAUserAlert]) {
        let alertsString = userAlerts.map { alert in
            "\(alert.type.rawValue) - \(alert.typeString ?? "None") - \(alert.string(at: 0) ?? "None")"
        }.joined(separator: "\n")
        
        MEGALogDebug("[Notifications] \(userAlerts.count)\n\(alertsString)")
    }
    
    @objc func showUpgradePlanView() {
        guard let navigationController else { return }
        UpgradeSubscriptionRouter(presenter: navigationController)
            .showUpgradeAccount()
    }
    
    @objc func notificationCellBackground(_ isNotificationSeen: Bool) -> UIColor {
        return isNotificationSeen ? TokenColors.Background.surface1 : TokenColors.Background.page
    }
    
    @objc func setupViewModelForCommandHandling() {
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewDidLoad)
    }
    
    @objc func dispatchActionsOnAppear() {
        viewModel.dispatch(.onViewDidAppear)
    }
    
    @objc func clearImageLoaderCache() {
        viewModel.dispatch(.clearImageCache)
    }
    
    @objc func didTapNotification(at indexPath: IndexPath) {
        guard indexPath.section == NotificationSection.promos.rawValue else { return }
        
        let notification = viewModel.promoList[indexPath.row]
        viewModel.dispatch(.didTapNotification(notification))
    }
    
    @objc func handleNodeNavigation(_ nodeHandle: HandleEntity) {
        viewModel.dispatch(.handleNodeNavigation(nodeHandle))
    }
    
    private func executeCommand(_ command: NotificationsViewModel.Command) {
        switch command {
        case .reloadData:
            tableView.reloadData()
        case .presentURLLink(let url):
            guard UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - BottomOverlayPresenterProtocol

extension NotificationsTableViewController: BottomOverlayPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
