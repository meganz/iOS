

extension ChatRoomsViewController {
    @objc func joinActiveCall(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else {
            return
        }
        
        MeetingContainerRouter(presenter: self,
                               chatRoom: ChatRoomEntity(with: chatRoom),
                               call: CallEntity(with: call),
                               isVideoEnabled: call.hasLocalVideo).start()
    }
}
