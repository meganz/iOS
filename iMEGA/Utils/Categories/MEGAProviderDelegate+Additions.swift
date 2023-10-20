import MEGADomain

extension MEGAProviderDelegate {
    @objc func answer(call: MEGAChatCall, chatRoom: MEGAChatRoom, presenter: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MeetingContainerRouter(
                presenter: presenter,
                chatRoom: chatRoom.toChatRoomEntity(),
                call: call.toCallEntity(),
                isSpeakerEnabled: chatRoom.isMeeting
            ).start()
        }
    }
    
    @objc func configureAudioSession() {
        RTCDispatcher.dispatchAsync(on: RTCDispatcherQueueType.typeAudioSession) {
            let audioSession = RTCAudioSession.sharedInstance()
            audioSession.lockForConfiguration()
            let configuration = RTCAudioSessionConfiguration.webRTC()
            configuration.categoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
            try? audioSession.setConfiguration(configuration)
            audioSession.unlockForConfiguration()
        }
    }
    
    @objc func isOneToOneChatRoom(_ chatRoom: MEGAChatRoom?) -> Bool {
        guard let chatRoom = chatRoom else { return false }
        return chatRoom.toChatRoomEntity().chatType == .oneToOne
    }
}
