import Foundation

extension MEGAChatListItem {

    var chatRoom: MEGAChatRoom? {
        return MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatId)
    }

    var peerCount: UInt {
        return chatRoom?.peerCount ?? 0
    }

    @objc var searchString: String {
        let fullnames = (0..<peerCount).compactMap { chatRoom?.fullName(atIndex: $0)}.joined(separator: " ")
        let nicknames = (0..<peerCount).compactMap { chatRoom?.userNickname(atIndex: $0) }.joined(separator: " ")
        let emails = (0..<peerCount).compactMap { chatRoom?.peerEmail(byHandle: chatRoom?.peerHandle(at: $0) ?? MEGAInvalidHandle) }.joined(separator: " ")
        
        guard let chatRoomTitle = title else {
            return fullnames + " " + nicknames + " " + emails
        }
        
        return chatRoomTitle + " " + fullnames + " " + nicknames + " " + emails
    }
    
    @objc func chatTitle() -> String {
        return chatRoom?.chatTitle() ?? ""
    }
}
