import MEGADomain
import MEGAL10n

extension ContactDetailsViewController {
    @objc func joinMeeting(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGAChatSdk.shared.chatCall(forChatId: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().isOutputEqualToPortType(.builtInSpeaker)
        MeetingContainerRouter(presenter: self,
                               chatRoom: chatRoom.toChatRoomEntity(),
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
    
    @objc func openChatRoom(chatId: HandleEntity, delegate: any MEGAChatRoomDelegate) {
        guard let chatRoom = ChatRoomRepository.sharedRepo.chatRoom(forChatId: chatId) else { return }
        if ChatRoomRepository.sharedRepo.isChatRoomOpen(chatRoom) {
            ChatRoomRepository.sharedRepo.closeChatRoom(chatId: chatId, delegate: delegate)
        }
        try? ChatRoomRepository.sharedRepo.openChatRoom(chatId: chatId, delegate: delegate)
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
