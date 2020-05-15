

extension ChatViewController: MEGAChatDelegate {
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if chatRoom.chatId == chatId {
            updateRightBarButtons()
        }
    }
}
