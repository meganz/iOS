import MEGADomain

extension ContactDetailsViewController {
    @objc func joinMeeting(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker)
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
}

// MARK: - NodeInfo
extension ContactDetailsViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(withNode: node)
    }
}
