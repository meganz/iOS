
extension MEGAProviderDelegate {
    @objc func answer(call: MEGAChatCall, chatRoom: MEGAChatRoom, presenter: UIViewController) {
        MeetingContainerRouter(
            presenter: presenter,
            chatRoom: ChatRoomEntity(with: chatRoom),
            call: CallEntity(with: call),
            isSpeakerEnabled: chatRoom.isMeeting
        ).start()
    }
    
    
    @objc func configureAudioSession() {
        RTCDispatcher.dispatchAsync(on: RTCDispatcherQueueType.typeAudioSession) {
            let audioSession = RTCAudioSession.sharedInstance()
            audioSession.lockForConfiguration()
            let configuration = RTCAudioSessionConfiguration.webRTC()
            configuration.categoryOptions = [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
            try? audioSession.setConfiguration(configuration)
            audioSession.unlockForConfiguration()
        }
    }
    
    @objc func isOneToOneChatRoom(_ chatRoom: MEGAChatRoom?) -> Bool {
        guard let chatRoom = chatRoom else { return false }
        return ChatRoomEntity(with: chatRoom).chatType == .oneToOne
    }
}
