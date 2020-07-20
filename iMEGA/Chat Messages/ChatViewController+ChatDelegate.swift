

extension ChatViewController: MEGAChatDelegate {
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk!, chatId: UInt64, newState: Int32) {
        if chatRoom.chatId == chatId {
            configureNavigationBar()
            checkIfChatHasActiveCall()
        }
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk!, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        if inProgress || userHandle == api.myUserHandle || chatRoom.isGroup {
            return
        }
        
        if chatRoom.peerHandle(at: 0) == userHandle,
        onlineStatus != .invalid {
            configureNavigationBar()
        }
    }
    
    func onChatPresenceLastGreen(_ api: MEGAChatSdk!, userHandle: UInt64, lastGreen: Int) {
        guard !chatRoom.isGroup else {
            return
        }
        
        
    }
}
