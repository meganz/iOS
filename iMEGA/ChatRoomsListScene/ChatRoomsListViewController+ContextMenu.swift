import MEGADomain

@available(iOS 14.0, *)
extension ChatRoomsListViewController: ChatMenuDelegate, MeetingContextMenuDelegate {
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
        button.addTarget(self, action: #selector(addBarButtonItemTapped), for: .touchUpInside)
    }
    
    private func setAddBarButtonWithMeetingsOptions() {
        addBarButtonItem.menu = contextMenuManager?.contextMenu(
            with: CMConfigEntity(
                menuType: .menu(type: .meeting),
                shouldScheduleMeeting: FeatureFlagProvider().isFeatureFlagEnabled(for: .scheduleMeeting)
            )
        )
        addBarButtonItem.target = nil
        addBarButtonItem.action = nil
    }
    
    private func setAddBarButtonWithChatOptions() {
        addBarButtonItem.target = self
        addBarButtonItem.action = #selector(addBarButtonItemTapped)
    }
    
    func refreshContextMenuBarButton() {
        moreBarButtonItem.menu = contextMenuManager?.contextMenu(with: contextMenuConfiguration())
    }
    
    func configureNavigationBarButtons(chatMode: ChatMode) {
        switch chatMode {
        case .chats:
            setAddBarButtonWithChatOptions()
        case .meetings:
            setAddBarButtonWithMeetingsOptions()
        }
        
        refreshContextMenuBarButton()
    }
    
    func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(chatMenuDelegate: self,
                                                meetingContextMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    }
    
    //MARK: - ChatMenuDelegate functions
    func chatStatusMenu(didSelect action: ChatStatusEntity) {
        viewModel.changeChatStatus(to: action)
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
    
    //MARK: - MeetingContextMenuDelegate functions
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
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        // iOS 13 not supported for this class
    }
}
