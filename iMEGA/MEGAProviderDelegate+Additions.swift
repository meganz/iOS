
extension MEGAProviderDelegate {
    @objc func answer(call: MEGAChatCall, chatRoom: MEGAChatRoom, presenter: UIViewController) {
        MeetingContainerRouter(
            presenter: presenter,
            chatRoom: ChatRoomEntity(with: chatRoom),
            call: CallEntity(with: call)
        ).start()
    }
}
