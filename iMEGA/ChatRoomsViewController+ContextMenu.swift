
extension ChatRoomsViewController: ChatMenuDelegate {
    
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .chat,
                       isDoNotDisturbEnabled: globalDNDNotificationControl?.isGlobalDNDEnabled ?? false,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl?.timeRemainingToDeactiveDND ?? "",
                       chatStatus: ChatStatus(rawValue: MEGASdkManager.sharedMEGAChatSdk().onlineStatus().rawValue) ?? .invalid)
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
            globalDNDNotificationControl?.turnOnDND(moreBarButtonItem as Any)
        } else {
            globalDNDNotificationControl?.turnOffDND { [weak self] in
                self?.refreshContextMenuBarButton()
            }
        }
    }
    
    @objc func refreshContextMenuBarButton() {
        if #available(iOS 14.0, *) {
            moreBarButtonItem?.menu = contextMenuManager?.contextMenu(with: contextMenuConfiguration())
        } else {
            moreBarButtonItem?.target = self
            moreBarButtonItem?.action = #selector(presentActionSheet(sender:))
        }
    }
    
    @objc func changeToOnlineStatus(_ status: MEGAChatStatus) {
        if status != MEGASdkManager.sharedMEGAChatSdk().onlineStatus() {
            MEGASdkManager.sharedMEGAChatSdk().setOnlineStatus(status)
        }
    }
    
    @objc func configureNavigationBarButtons() {
        addBarButtonItem?.target = self
        addBarButtonItem?.action = #selector(showStartConversation)
        
        refreshContextMenuBarButton()
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
        dndSwitch.setOn(globalDNDNotificationControl?.isGlobalDNDEnabled ?? false, animated: false)
        
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
        globalDNDNotificationControl?.turnOnDND(dndTurnOnOption: option) { [weak self] in
            if #available(iOS 14, *) {
                self?.refreshContextMenuBarButton()
            }
        }
    }
    
    func chatDisableDoNotDisturb() {
        guard globalDNDNotificationControl?.isGlobalDNDEnabled ?? false else { return }
        
        globalDNDNotificationControl?.turnOffDND { [weak self] in
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
