import ChatRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGAUI

extension ContactDetailsViewController {
    
    @objc func openSharedFolderAtIndexPath(_ indexPath: IndexPath) {
        guard
            let navigationController = navigationController,
            let node = incomingNodeListForUser.node(at: indexPath.row)
        else { return }
        
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let vc = factory.buildBare(parentNode: node.toNodeEntity())
        guard let vc else { return }
        navigationController.pushViewController(vc, animated: true)
    }
    
    @objc func joinMeeting(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGAChatSdk.shared.chatCall(forChatId: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().isOutputEqualToPortType(.builtInSpeaker)
        MeetingContainerRouter(
            presenter: self,
            chatRoom: chatRoom.toChatRoomEntity(),
            call: call.toCallEntity(),
            isSpeakerEnabled: isSpeakerEnabled
        ).start()
    }
    
    @objc func openChatRoom(chatId: HandleEntity, delegate: any MEGAChatRoomDelegate) {
        let chatRoomRepository = ChatRoomRepository.newRepo
        
        guard let chatRoom = chatRoomRepository.chatRoom(forChatId: chatId) else { return }
        if chatRoomRepository.isChatRoomOpen(chatRoom) {
            chatRoomRepository.closeChatRoom(chatId: chatId, delegate: delegate)
        }
        try? chatRoomRepository.openChatRoom(chatId: chatId, delegate: delegate)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
    }
    
    @objc func startCall(inChatRoom chatRoom: MEGAChatRoom, video: Bool) {
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let chatIdBase64Handle = megaHandleUseCase.base64Handle(forUserHandle: chatRoom.chatId) ?? "Unknown"
        CallKitCallManager.shared.startCall(in: chatRoom.toChatRoomEntity(), chatIdBase64Handle: chatIdBase64Handle, hasVideo: video, notRinging: false, isJoiningActiveCall: false)
    }
}

extension ContactDetailsViewController: PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        tableView?.reloadData()
    }
    
    func pushNotificationSettingsLoaded() {
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ContactTableViewCell else {
            return
        }
        if cell.controlSwitch != nil {
            cell.controlSwitch.isEnabled = true
        }
    }
    
    @objc
    func assignBackButton() {
        // This button is not actually visible, in this screen we are using a custom back button
        // not a real one managed by UINavigationBar.
        // But this needs to be assigned nevertheless, so that it's visible
        // to the screens that originate from contact details and
        // need to navigate back to it. We need this to generate
        // correct menu items on long press on back button
        setMenuCapableBackButtonWith(menuTitle: Strings.Localizable.ContactInfo.BackButton.menu)
    }
    
    @objc
    func updateAppearance() {
        actionsView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_backgroundElevated(traitCollection)
        actionsBottomSeparatorView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : UIColor.mnz_separator(for: traitCollection)
        let buttonTextColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.mnz_secondaryGray(for: traitCollection)
        messageLabel.textColor = buttonTextColor
        callLabel.textColor = buttonTextColor
        videoLabel.textColor = buttonTextColor
        
        messageButton.contentMode = .scaleAspectFit
        callButton.contentMode = .scaleAspectFit
        videoCallButton.contentMode = .scaleAspectFit
        
        if UIColor.isDesignTokenEnabled() {
            let message = MEGAAssetsPreviewImageProvider.image(named: "sendMessageRound_token")
            messageButton.setImage(message, for: .normal)
            messageButton.setImage(message?.applying(alpha: 0.5), for: .disabled)
            let call = MEGAAssetsPreviewImageProvider.image(named: "makeCallRound_token")
            callButton.setImage(call, for: .normal)
            callButton.setImage(message?.applying(alpha: 0.5), for: .disabled)
            let videoCall = MEGAAssetsPreviewImageProvider.image(named: "callVideoRound_token")
            videoCallButton.setImage(videoCall, for: .normal)
            videoCallButton.setImage(videoCall?.applying(alpha: 0.5), for: .disabled)
        }
    }
    
    @objc
    func updateHeaderBackgroundColor(headerView: GenericHeaderFooterView) {
        if UIColor.isDesignTokenEnabled() {
            headerView.tokenBackgroundColor = TokenColors.Background.page
        }
    }
    
    @objc func reloadTableViewAsync() {
        Task {
            await MainActor.run {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - NodeInfo
extension ContactDetailsViewController {
    @objc
    func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(withNode: node, featureFlagProvider: DIContainer.featureFlagProvider)
    }
    
    @objc
    func addMenuTo(backButton: UIButton) {
        if let navigationController = self.navigationController as? MEGANavigationController {
            backButton.menu = UIMenu(items: navigationController.currentBackButtonMenuItems())
        }
    }
}
