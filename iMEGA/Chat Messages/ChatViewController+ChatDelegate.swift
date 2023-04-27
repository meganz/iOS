

extension ChatViewController: MEGAChatDelegate {
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        if chatRoom.chatId == chatId {
            configureNavigationBar()
            chatContentViewModel.dispatch(.updateContent)
        }
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        if inProgress || userHandle == api.myUserHandle || chatRoom.isGroup {
            return
        }
        
        if chatRoom.peerHandle(at: 0) == userHandle,
           onlineStatus != .invalid {
            configureNavigationBar()
            switch chatRoom.onlineStatus {
            case .offline, .away:
                api.requestLastGreen(userHandle)
            default:
                break
            }
        }
    }
    
    func onChatPresenceLastGreen(_ api: MEGAChatSdk, userHandle: UInt64, lastGreen: Int) {
        switch chatRoom.onlineStatus {
        case .offline, .away:
            if let titleView = navigationItem.titleView as? ChatTitleView {
                titleView.lastGreen = lastGreen
            }
        default:
            break
        }
    }
}
