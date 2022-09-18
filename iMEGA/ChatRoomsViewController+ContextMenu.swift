import MEGADomain

extension ChatRoomsViewController: ChatMenuDelegate, MeetingContextMenuDelegate {
    
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .chat),
                       isDoNotDisturbEnabled: globalDNDNotificationControl?.isGlobalDNDEnabled ?? false,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl?.timeRemainingToDeactiveDND ?? "",
                       chatStatus: ChatStatus(rawValue: MEGASdkManager.sharedMEGAChatSdk().onlineStatus().rawValue)?.toChatStatusEntity() ?? .invalid)
    }
    
    @objc func setEmptyViewButtonWithMeetingsOptions(button: UIButton) {
        if #available(iOS 14.0, *) {
            button.menu = contextMenuManager?.contextMenu(with: CMConfigEntity(menuType: .menu(type: .meeting)))
            button.showsMenuAsPrimaryAction = true
        } else {
            button.addTarget(self, action: #selector(presentMeetingActionSheet(sender:)), for: .touchUpInside)
        }
    }
    
    @objc func setEmptyViewButtonWithChatOptions(button: UIButton) {
        button.addTarget(self, action: #selector(showStartConversation), for: .touchUpInside)
    }
    
    private func setAddBarButtonWithMeetingsOptions() {
        if #available(iOS 14.0, *) {
            addBarButtonItem?.menu = contextMenuManager?.contextMenu(
                with: CMConfigEntity(
                    menuType: .menu(type: .meeting),
                    shouldScheduleMeeting: FeatureFlagProvider().isFeatureFlagEnabled(for: .scheduleMeeting)
                )
            )
            addBarButtonItem?.target = nil
            addBarButtonItem?.action = nil
        } else {
            addBarButtonItem?.target = self
            addBarButtonItem?.action = #selector(presentMeetingActionSheet(sender:))
        }
    }
    
    private func setAddBarButtonWithChatOptions() {
        addBarButtonItem?.target = self
        addBarButtonItem?.action = #selector(showStartConversation)
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
        if chatTypeSelected == .meeting {
            setAddBarButtonWithMeetingsOptions()
        } else {
            setAddBarButtonWithChatOptions()
        }
        
        refreshContextMenuBarButton()
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
        let actionSheetVC = ActionSheetViewController(actions: actions.compactMap { $0.type == CMElementTypeEntity.chat(actionType: .doNotDisturb) ? convertToSwitchAction(action: $0) : $0},
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
    
    @objc func presentMeetingActionSheet(sender: Any) {
        guard let actions = contextMenuManager?.actionSheetActions(with: CMConfigEntity(menuType: .menu(type: .meeting))) else { return }
        
        let actionSheetVC = ActionSheetViewController(
            actions: actions,
            headerTitle: nil,
            dismissCompletion: nil,
            sender: sender)
        
        present(actionSheetVC, animated: true)
    }
    
    //MARK: - ChatMenuDelegate functions
    func chatStatusMenu(didSelect action: ChatStatusEntity) {
        switch action {
        case .online:
            changeTo(onlineStatus: .online)
        case .away:
            changeTo(onlineStatus:.away)
        case .busy:
            changeTo(onlineStatus: .busy)
        case .offline:
            changeTo(onlineStatus: .offline)
        default:
            break
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
    
    func meetingContextMenu(didSelect action: MeetingActionEntity) {
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
        case .scheduleMeeting:
            break
        }
    }
}
