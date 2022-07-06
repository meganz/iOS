
extension ChatRoomsViewController: ChatMenuDelegate, MeetingContextMenuDelegate {
    
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .chat,
                       isDoNotDisturbEnabled: globalDNDNotificationControl.isGlobalDNDEnabled,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl.timeRemainingToDeactiveDND,
                       chatStatus: ChatStatus(rawValue: MEGASdkManager.sharedMEGAChatSdk().onlineStatus().rawValue) ?? .invalid)
    }
    
    @objc func setEmptyViewButtonWithMeetingsOptions(button: UIButton) {
        if #available(iOS 14.0, *) {
            button.menu = contextMenuManager?.contextMenu(with: CMConfigEntity(menuType: .meeting))
            button.showsMenuAsPrimaryAction = true
        } else {
            button.addTarget(self, action: #selector(presentMeetingActionSheet(sender:)), for: .touchUpInside)
        }
    }
    
    @objc func setEmptyViewButtonWithChatOptions(button: UIButton) {
        button.addTarget(self, action: #selector(showStartConversation), for: .touchUpInside)
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
    
    private func setAddBarButtonWithMeetingsOptions() {
        if #available(iOS 14.0, *) {
            addBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                               menu: contextMenuManager?.contextMenu(with: CMConfigEntity(menuType: .meeting)))
        } else {
            addBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                               style: .plain,
                                               target: self,
                                               action: #selector(presentMeetingActionSheet(sender:)))
        }
    }
    
    private func setAddBarButtonWithChatOptions() {
        addBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                           style: .plain,
                                           target: self,
                                           action: #selector(showStartConversation))
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
        setContextMenuBarButton()
                
        if chatTypeSelected == .meeting {
            setAddBarButtonWithMeetingsOptions()
        } else {
            setAddBarButtonWithChatOptions()
        }
        
        navigationItem.rightBarButtonItems = [moreBarButtonItem, addBarButtonItem]
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(chatMenuDelegate: self,
                                                meetingContextMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
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
    
    @objc func presentMeetingActionSheet(sender: Any) {
        guard let actions = contextMenuManager?.actionSheetActions(with: CMConfigEntity(menuType: .meeting)) else { return }
        
        let actionSheetVC = ActionSheetViewController(
            actions: actions,
            headerTitle: nil,
            dismissCompletion: nil,
            sender: sender)
        
        present(actionSheetVC, animated: true)
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
    
    func meetingContextMenu(didSelect action: MeetingAction) {
        if MEGASdkManager.sharedMEGAChatSdk().mnz_existsActiveCall {
            MeetingAlreadyExistsAlert.show(presenter: self)
            return
        }
        
        switch action {
        case .startMeeting:
            MeetingCreatingViewRouter(
                viewControllerToPresent: self,
                type: .start,
                link: nil,
                userhandle: 0
            ).start()
        case .joinMeeting:
            EnterMeetingLinkRouter(
                viewControllerToPresent: self,
                isGuest: false
            ).start()
        }
    }
}
