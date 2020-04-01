

import Foundation
import MessageKit

class ChatRoomDelegate: NSObject, MEGAChatRoomDelegate {
    
    // MARK: - Properties

    let chatRoom: MEGAChatRoom
    let collectionView: MessagesCollectionView
    var messages: [ChatMessage] = []
    var isChatRoomOpen: Bool = false
    
    var isFullChatHistoryLoaded: Bool {
        return MEGASdkManager.sharedMEGAChatSdk()!.isFullHistoryLoaded(forChat: chatRoom.chatId)
    }
    
    // MARK: - Init

    init(chatRoom: MEGAChatRoom, collectionView: MessagesCollectionView) {
        self.chatRoom = chatRoom
        self.collectionView = collectionView
        super.init()
    }
    
    // MARK: - MEGAChatRoomDelegate methods

    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        print("onChatRoomUpdate \(chatRoom)")
    }
    
    func onMessageLoaded(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        if let chatMessage = message {
            messages.append(ChatMessage(message: chatMessage, chatRoom: chatRoom))
        } else {
            messages = messages.reversed()
            collectionView.reloadData()
            collectionView.scrollToBottom()
        }
    }
    
    func onMessageReceived(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        print("onMessageReceived")
    }
    
    func onMessageUpdate(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        print("onMessageUpdate")
    }
    
    func onHistoryReloaded(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        print("onHistoryReloaded")
    }
    
    // MARK: - Interface methods

    func loadMoreMessages() {
        if !isFullChatHistoryLoaded {
            loadMessages()
        }
    }
    
    func openChatRoom() {
        guard isChatRoomOpen == false else {
            MEGALogDebug("openChatRoom: Trying to open already opened chat room")
            return
        }
        
        isChatRoomOpen = MEGASdkManager.sharedMEGAChatSdk()!.openChatRoom(chatRoom.chatId, delegate: self)
        if isChatRoomOpen {
            loadMessages()
        } else {
            MEGALogError("OpenChatRoom: Cannot open chat room with id \(chatRoom.chatId)")
        }
    }
    
    func closeChatRoom() {
        if isChatRoomOpen {
            MEGASdkManager.sharedMEGAChatSdk()!.closeChatRoom(chatRoom.chatId, delegate: self)
        }
    }
    
    // MARK: - Private methods
    
    private func loadMessages(count: Int = 32) {
        switch MEGASdkManager.sharedMEGAChatSdk()!.loadMessages(forChat: chatRoom.chatId, count: count){
        case .error:
            MEGALogDebug("loadMessagesForChat: history has to be fetched from server, but we are not logged in yet")
        case .none:
            MEGALogDebug("loadMessagesForChat: there's no more history available (not even in the server)")
        case .local:
            MEGALogDebug("loadMessagesForChat: messages will be fetched locally")
        case .remote:
            MEGALogDebug("loadMessagesForChat: messages will be requested to the server")
        @unknown default:
            MEGALogError("loadMessagesForChat: unknown case executed")
        }
    }
}
