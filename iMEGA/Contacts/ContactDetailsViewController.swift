
extension ContactDetailsViewController {
    @objc func joinMeeting(withChatRoom chatRoom: MEGAChatRoom, isVideoEnabled: Bool) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker)
        MeetingContainerRouter(presenter: self,
                               chatRoom: ChatRoomEntity(with: chatRoom),
                               call: CallEntity(with: call),
                               isVideoEnabled: isVideoEnabled,
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
}
