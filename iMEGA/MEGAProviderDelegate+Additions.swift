
extension MEGAProviderDelegate {
    @objc func answer(call: MEGAChatCall, chatRoom: MEGAChatRoom, presenter: UIViewController) {
        MeetingContainerRouter(
            presenter: presenter,
            chatRoom: ChatRoomEntity(with: chatRoom),
            call: CallEntity(with: call),
            isVideoEnabled: call.hasLocalVideo,
            isSpeakerEnabled: chatRoom.isMeeting,
            isAnsweredFromCallKit: true
        ).start()
    }
}
