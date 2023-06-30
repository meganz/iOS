import MEGAData
import MEGADomain
import MEGAPermissions

extension ChatRoomsViewController: ChatMenuDelegate, MeetingContextMenuDelegate {
    
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .chat),
                       isDoNotDisturbEnabled: globalDNDNotificationControl?.isGlobalDNDEnabled ?? false,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl?.timeRemainingToDeactiveDND ?? "",
                       chatStatus: ChatStatus(rawValue: MEGASdkManager.sharedMEGAChatSdk().onlineStatus().rawValue)?.toChatStatusEntity() ?? .invalid)
    }
    
    @objc func setEmptyViewButtonWithMeetingsOptions(button: UIButton) {
        button.menu = contextMenuManager?.contextMenu(with: CMConfigEntity(menuType: .menu(type: .meeting)))
        button.showsMenuAsPrimaryAction = true
    }
    
    @objc func setEmptyViewButtonWithChatOptions(button: UIButton) {
        button.addTarget(self, action: #selector(showStartConversation), for: .touchUpInside)
    }
    
    private func setAddBarButtonWithMeetingsOptions() {
        addBarButtonItem?.menu = contextMenuManager?.contextMenu(
            with: CMConfigEntity(
                menuType: .menu(type: .meeting),
                shouldScheduleMeeting: false
            )
        )
        addBarButtonItem?.target = nil
        addBarButtonItem?.action = nil
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
            globalDNDNotificationControl?.turnOnDND(isChatTypeMeeting: chatTypeSelected == .meeting, sender: moreBarButtonItem as Any)
        } else {
            globalDNDNotificationControl?.turnOffDND { [weak self] in
                self?.refreshContextMenuBarButton()
            }
        }
    }
    
    @objc func refreshContextMenuBarButton() {
        moreBarButtonItem?.menu = contextMenuManager?.contextMenu(with: contextMenuConfiguration())
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
    
    // MARK: - ChatMenuDelegate functions
    func chatStatusMenu(didSelect action: ChatStatusEntity) {
        switch action {
        case .online:
            changeTo(onlineStatus: .online)
        case .away:
            changeTo(onlineStatus: .away)
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
            self?.refreshContextMenuBarButton()
        }
    }
    
    func chatDisableDoNotDisturb() {
        guard globalDNDNotificationControl?.isGlobalDNDEnabled ?? false else { return }
        
        globalDNDNotificationControl?.turnOffDND { [weak self] in
            self?.refreshContextMenuBarButton()
        }
    }
    
    func archivedChatsTapped() {
        guard let archivedChatRoomsViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatRoomsViewControllerID") as? ChatRoomsViewController else { return }
        archivedChatRoomsViewController.chatRoomsType = .archived
        navigationController?.pushViewController(archivedChatRoomsViewController, animated: true)
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
    
    @objc
    func askNotificationPermissionsIfNeeded() {
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        permissionHandler.shouldAskForNotificationsPermissions { shouldAsk in
            guard shouldAsk else { return }
            PermissionAlertRouter
                .makeRouter(deviceHandler: permissionHandler)
                .presentModalNotificationsPermissionPrompt()
        }
    }
    
    @objc
    var hasAuthorizedContacts: Bool {
        DevicePermissionsHandler.makeHandler().hasContactsAuthorization
    }

}
