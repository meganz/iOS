
extension ChatRoomsViewController: ChatMenuDelegate {
    
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .chat,
                       isDoNotDisturbEnabled: globalDNDNotificationControl.isGlobalDNDEnabled,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl.timeRemainingToDeactiveDND,
                       chatStatus: ChatStatus(rawValue: MEGASdkManager.sharedMEGAChatSdk().onlineStatus().rawValue) ?? .invalid)
    }
    
    private func setContextMenuBarButton() {
        if #available(iOS 14.0, *) {
            moreBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
        } else {
            moreBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                style: .plain,
                                                target: self,
                                                action: #selector(presentActionSheet(sender:)))
        }
    }
    
    private func changeTo(onlineStatus: MEGAChatStatus) {
        if onlineStatus != MEGASdkManager.sharedMEGAChatSdk().onlineStatus() {
            MEGASdkManager.sharedMEGAChatSdk().setOnlineStatus(onlineStatus)
        }
    }
    
    @objc func changeDNDStatus(sender: Any) {
        guard let dndSwitch = sender as? UISwitch else { return }
        
        if dndSwitch.isOn {
            dismiss(animated: true, completion: nil)
            globalDNDNotificationControl.turnOnDND(moreBarButtonItem)
        } else {
            globalDNDNotificationControl.turnOffDND { [weak self] in
                self?.refreshContextMenuBarButton()
            }
        }
    }
    
    @objc func refreshContextMenuBarButton() {
        setContextMenuBarButton()
        navigationItem.rightBarButtonItems = [moreBarButtonItem, addBarButtonItem]
    }
    
    @objc func changeToOnlineStatus(_ status: MEGAChatStatus) {
        if status != MEGASdkManager.sharedMEGAChatSdk().onlineStatus() {
            MEGASdkManager.sharedMEGAChatSdk().setOnlineStatus(status)
        }
    }
    
    @objc func setNavigationBarButtons() {
        addBarButtonItem = UIBarButtonItem(image: Asset.Images.Chat.NavigationBar.startConversation.image,
                                           style: .plain,
                                           target: self,
                                           action: #selector(showStartConversation))
        
        setContextMenuBarButton()
        
        navigationItem.rightBarButtonItems = [moreBarButtonItem, addBarButtonItem]
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(chatMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository()))
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let actions = contextMenuManager?.actionSheetActions(with: contextMenuConfiguration()) else { return }
        presentActionSheet(actions: actions)
    }
    
    @objc func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions.compactMap { $0.identifier == ChatAction.doNotDisturb.rawValue ? convertToSwitchAction(action: $0) : $0},
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)

        self.present(actionSheetVC, animated: true)
    }
    
    private func convertToSwitchAction(action: ContextActionSheetAction) -> ActionSheetSwitchAction {
        let dndSwitch = UISwitch(frame: .zero)
        dndSwitch.addTarget(self, action: #selector(changeDNDStatus(sender:)), for: .valueChanged)
        dndSwitch.setOn(globalDNDNotificationControl.isGlobalDNDEnabled, animated: false)
        
        return ActionSheetSwitchAction(title: action.title,
                                       detail: action.detail,
                                       switchView: dndSwitch,
                                       image: action.image,
                                       style: .default) {
            action.actionHandler(action)
        }
    }
    
    //MARK: - ChatMenuDelegate functions
    func chatStatusMenu(didSelect action: ChatStatusAction) {
        switch action {
        case .online:
            changeTo(onlineStatus: .online)
        case .away:
            changeTo(onlineStatus:.away)
        case .busy:
            changeTo(onlineStatus: .busy)
        case .offline:
            changeTo(onlineStatus: .offline)
        }
    }
    
    func chatDoNotDisturbMenu(didSelect option: DNDTurnOnOption) {
        globalDNDNotificationControl.turnOnDND(dndTurnOnOption: option) { [weak self] in
            if #available(iOS 14, *) {
                self?.refreshContextMenuBarButton()
            }
        }
    }
    
    func chatDisableDoNotDisturb() {
        guard globalDNDNotificationControl.isGlobalDNDEnabled else { return }
        
        globalDNDNotificationControl.turnOffDND { [weak self] in
            if #available(iOS 14, *) {
                self?.refreshContextMenuBarButton()
            }
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
