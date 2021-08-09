
extension MEGAProviderDelegate {
    @objc func answer(call: MEGAChatCall, chatRoom: MEGAChatRoom, presenter: UIViewController) {
        MeetingContainerRouter(
            presenter: presenter,
            chatRoom: ChatRoomEntity(with: chatRoom),
            call: CallEntity(with: call),
            isVideoEnabled: call.hasLocalVideo,
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
}
