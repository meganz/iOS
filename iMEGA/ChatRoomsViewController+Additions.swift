import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASDKRepo

extension ChatRoomsViewController: ChatMenuDelegate, MeetingContextMenuDelegate {
    
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .chat),
                       isDoNotDisturbEnabled: globalDNDNotificationControl?.isGlobalDNDEnabled ?? false,
                       timeRemainingToDeactiveDND: globalDNDNotificationControl?.timeRemainingToDeactiveDND ?? "",
                       chatStatus: ChatStatus(rawValue: onlineStatus.rawValue)?.toChatStatusEntity() ?? .invalid)
    }
    
    private var sdk: MEGAChatSdk {
        MEGAChatSdk.shared
    }
    
    @objc var onlineStatus: MEGAChatStatus {
        get {
            sdk.onlineStatus()
        }
        set {
            if newValue != sdk.onlineStatus() {
                sdk.setOnlineStatus(newValue)
            }
        }
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
        if let newStatus = action.toMEGAChatStatus {
            onlineStatus = newStatus
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
        if MEGAChatSdk.shared.mnz_existsActiveCall {
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
    
    @objc func askNotificationPermissionsIfNeeded() {
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        permissionHandler.shouldAskForNotificationsPermissions { shouldAsk in
            guard shouldAsk else { return }
            PermissionAlertRouter
                .makeRouter(deviceHandler: permissionHandler)
                .presentModalNotificationsPermissionPrompt()
        }
    }
    
    @objc var hasAuthorizedContacts: Bool {
        DevicePermissionsHandler.makeHandler().hasContactsAuthorization
    }
    
    private func configureDefaultTitleWith(chatStatus: MEGAChatStatus) {
        let onlineStatusString = NSString.chatStatusString(chatStatus)
        let title = Strings.Localizable.Chat.title
        
        defer {
            // set the proper menu item always
            setMenuCapableBackButtonWith(menuTitle: title)
        }
        
        guard let onlineStatusString else {
            navigationItem.titleView = nil
            navigationItem.title = title
            return
        }
        
        navigationItem.titleView = customTitleViewWith(title: title, subtitle: onlineStatusString)
    }
    
    private func customTitleViewWith(title: String, subtitle: String) -> UIView {
        let label = UILabel().customNavigationBarLabel(title: title, subtitle: subtitle)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: 0, width: label.bounds.size.width, height: 44)
        return label
    }
    
    @objc func customNavigationBarLabel() {
        customNavigationBarLabel(chatStatus: onlineStatus)
    }

    private func customNavigationBarLabel(chatStatus: MEGAChatStatus) {
        switch chatRoomsType {
        case .default:
            configureDefaultTitleWith(chatStatus: chatStatus)
        case .archived:
            let title = Strings.Localizable.archivedChats
            navigationItem.title = title
            setMenuCapableBackButtonWith(menuTitle: title)
        @unknown default:
            configureDefaultTitleWith(chatStatus: chatStatus)
        }
    }
}

fileprivate extension ChatStatusEntity {
    // this mapping is for this VC particular use case and is not handling all possible cases
    var toMEGAChatStatus: MEGAChatStatus? {
        switch self {
        case .online:   return .online
        case .away:     return .away
        case .busy:     return .busy
        case .offline:  return .offline
        default:        return nil
        }
    }
}
