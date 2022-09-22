import MEGADomain

extension ContactDetailsViewController {
    @objc func joinMeeting(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker)
        MeetingContainerRouter(presenter: self,
                               chatRoom: ChatRoomEntity(with: chatRoom),
                               call: CallEntity(with: call),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
    
    @objc func openChatRoom(chatId: HandleEntity, delegate: MEGAChatRoomDelegate) {
        if ChatRoomRepository.sharedRepo.isChatRoomOpen(chatId: chatId) {
            ChatRoomRepository.sharedRepo.closeChatRoom(chatId: chatId, delegate: delegate)
        }
        try? ChatRoomRepository.sharedRepo.openChatRoom(chatId: chatId, delegate: delegate)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
    }
}
