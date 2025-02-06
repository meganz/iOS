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
        MeetingContainerRouter(
            presenter: self,
            chatRoom: chatRoom.toChatRoomEntity(),
            call: call.toCallEntity()
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
    
    @objc func startCall(inChatRoom chatRoom: MEGAChatRoom, videoEnabled: Bool) {
        CallControllerProvider().provideCallController().startCall(
            with: CallActionSync(
                chatRoom: chatRoom.toChatRoomEntity(),
                speakerEnabled: videoEnabled,
                videoEnabled: videoEnabled
            )
        )
    }
    
    @objc func readWritePermissionsIcon() -> UIImage {
        UIImage(resource: .readWritePermissions)
            .withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysOriginal)
    }
    
    @objc func moderatorIcon() -> UIImage {
        UIImage(resource: .moderator)
            .withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysOriginal)
    }
    
    @objc func standardIcon() -> UIImage {
        UIImage(resource: .standard)
            .withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysOriginal)
    }
    
    @objc func readOnlyChatIcon() -> UIImage {
        UIImage(resource: .readOnlyChat)
            .withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysOriginal)
    }
    
    @objc var redIconColor: UIColor {
        TokenColors.Support.error
    }
    
    @objc var redTextColor: UIColor {
        TokenColors.Text.error
    }
    
    @objc var primaryIconColor: UIColor {
        TokenColors.Icon.primary
    }
    
    @objc func removeParticipantFromGroup() {
        guard !isUserActionInProgress else { return }
        userActionInProgress(true)
        Task {
            do {
                let chatRoomRepository = ChatRoomRepository.newRepo
                try await chatRoomRepository.remove(fromChat: groupChatRoom.toChatRoomEntity(), userId: userHandle)
                navigationController?.popViewController(animated: true) { [weak self] in
                    self?.userActionInProgress(false)
                }
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                userActionInProgress(false)
            }
        }
    }
    
    private func userActionInProgress(_ inProgress: Bool) {
        if inProgress {
            isUserActionInProgress = true
            SVProgressHUD.show()
        } else {
            isUserActionInProgress = false
            SVProgressHUD.dismiss()
        }
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
    func setupColors() {
        actionsView.backgroundColor = TokenColors.Background.page
        actionsBottomSeparatorView.backgroundColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = TokenColors.Border.strong
        let buttonTextColor = TokenColors.Text.primary
        messageLabel.textColor = buttonTextColor
        callLabel.textColor = buttonTextColor
        videoLabel.textColor = buttonTextColor
        
        messageButton.contentMode = .scaleAspectFit
        callButton.contentMode = .scaleAspectFit
        videoCallButton.contentMode = .scaleAspectFit
        
        messageButton.setImage(UIImage.sendMessageRoundToken, for: .normal)
        messageButton.setImage(UIImage.sendMessageRoundToken.applying(alpha: 0.5), for: .disabled)
        
        let call = MEGAAssetsImageProvider.image(named: "makeCallRound_token")
        callButton.setImage(call, for: .normal)
        callButton.setImage(UIImage.sendMessageRoundToken.applying(alpha: 0.5), for: .disabled)
        let videoCall = MEGAAssetsImageProvider.image(named: "callVideoRound_token")
        videoCallButton.setImage(videoCall, for: .normal)
        videoCallButton.setImage(videoCall?.applying(alpha: 0.5), for: .disabled)
    }
    
    @objc
    func updateHeaderBackgroundColor(headerView: GenericHeaderFooterView) {
        headerView.tokenBackgroundColor = TokenColors.Background.page
    }
}

// MARK: - NodeInfo
extension ContactDetailsViewController {
    @objc
    func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(
            withNode: node,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
    }
    
    @objc
    func addMenuTo(backButton: UIButton) {
        if let navigationController = self.navigationController as? MEGANavigationController {
            backButton.menu = UIMenu(items: navigationController.currentBackButtonMenuItems())
        }
    }
}
