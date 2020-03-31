

import Foundation
import MessageKit

class ChatRoomDelegate: NSObject, MEGAChatRoomDelegate {
    
    let chatRoom: MEGAChatRoom
    let collectionView: MessagesCollectionView
    var messages: Set<MEGAChatMessage> = []
    
    // MARK: - Init

    init(chatRoom: MEGAChatRoom, collectionView: MessagesCollectionView) {
        self.chatRoom = chatRoom
        self.collectionView = collectionView
        
        super.init()
        
        if MEGASdkManager.sharedMEGAChatSdk()!.openChatRoom(chatRoom.chatId, delegate: self) {
            loadMessages()
        } else {
            MEGALogError("OpenChatRoom: Cannot open chat room with id \(chatRoom.chatId)")
        }
    }
    
    // MARK: - MEGAChatRoomDelegate methods

    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        print("onChatRoomUpdate \(chatRoom)")
    }
    
    func onMessageLoaded(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        if message != nil {
            messages.insert(message)
        } else {
            collectionView.reloadData()
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
        if MEGASdkManager.sharedMEGAChatSdk()!.isFullHistoryLoaded(forChat: chatRoom.chatId) == false {
            loadMessages()
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
