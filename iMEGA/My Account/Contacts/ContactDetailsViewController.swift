import ChatRepo
import MEGADomain
import MEGAL10n

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
        MeetingContainerRouter(presenter: self,
                               chatRoom: chatRoom.toChatRoomEntity(),
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
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
        // This button is not visible , using a custom back button
        // but this needs to be assigned, so that it's visible
        // to the screens that originate from contact details and
        // need to navigate back to it. We need this to generate
        // correct menu items on long press on back button
        setMenuCapableBackButtonWith(menuTitle: Strings.Localizable.ContactInfo.BackButton.menu)
    }
}

// MARK: - NodeInfo
extension ContactDetailsViewController {
    @objc
    func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(withNode: node)
    }
    
    @objc
    func addMenuTo(backButton: UIButton) {
        if let navigationController = self.navigationController as? MEGANavigationController {
            backButton.menu = UIMenu(items: navigationController.currentBackButtonMenuItems())
        }
    }
}
