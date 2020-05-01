

import Foundation
import MessageKit

class ChatRoomDelegate: NSObject, MEGAChatRoomDelegate {
    
    // MARK: - Properties

    let chatRoom: MEGAChatRoom
    weak var chatViewController: ChatViewController!
    var messages: [ChatMessage] = []
    var isChatRoomOpen: Bool = false
    var historyMessages: [ChatMessage] = []
    
    var isFullChatHistoryLoaded: Bool {
        return MEGASdkManager.sharedMEGAChatSdk()!.isFullHistoryLoaded(forChat: chatRoom.chatId)
    }
    
    // MARK: - Init

    init(chatRoom: MEGAChatRoom, chatViewController: ChatViewController) {
        self.chatRoom = chatRoom
        self.chatViewController = chatViewController
        super.init()
    }
    
    // MARK: - MEGAChatRoomDelegate methods

    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        MEGALogInfo("ChatRoomDelegate: onChatRoomUpdate \(chatRoom)")
        chatViewController.chatRoom = chat
        
        switch chat.changes {
        case .userTyping:
            if (chat.userTypingHandle != api.myUserHandle) {
                chatViewController.setTypingIndicatorViewHidden(false, animated: true ,whilePerforming: nil) { [weak self] success in
                    if success, self?.isLastSectionVisible() == true {
                        self?.chatViewController.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
            }
        case .userStopTyping:
            chatViewController.setTypingIndicatorViewHidden(true, animated: true ,whilePerforming: nil)  { [weak self] success in
                if success, self?.isLastSectionVisible() == true {
                    self?.chatViewController.messagesCollectionView.scrollToBottom(animated: true)
                }
            }
        default:
            break
        }
    }
    
    func onMessageLoaded(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        MEGALogInfo("ChatRoomDelegate: onMessageLoaded")
        
        if isFullChatHistoryLoaded {
            chatViewController.messagesCollectionView.refreshControl = nil
        }
        
        if let chatMessage = message {
            if !chatMessage.isDeleted {
                if chatMessage.status == .sending || chatMessage.status == .sendingManual {
                    historyMessages.append(ChatMessage(message: chatMessage, chatRoom: chatRoom))
                } else {
                    historyMessages.insert(ChatMessage(message: chatMessage, chatRoom: chatRoom), at: 0)
                }
            }
        } else {
            if messages.count == 0 {
                messages = historyMessages
                historyMessages.removeAll()
                chatViewController.messagesCollectionView.reloadData()
                chatViewController.messagesCollectionView.scrollToBottom()
                return
            }
            
            messages = historyMessages + messages
            historyMessages.removeAll()
            chatViewController.messagesCollectionView.reloadDataAndKeepOffset()
            chatViewController.messagesCollectionView.refreshControl?.endRefreshing()
        }
    }
    
    func onMessageReceived(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        MEGALogInfo("ChatRoomDelegate: onMessageReceived")

        guard let chatMessage = message else {
            MEGALogError("ChatRoomDelegate: onMessageReceived - message is nil")
            return
        }
        
        if UIApplication.shared.applicationState == .active
        && UIApplication.mnz_visibleViewController() == self {
            MEGASdkManager.sharedMEGAChatSdk()?.setMessageSeenForChat(chatRoom.chatId, messageId: message.messageId)
        }

        insertMessage(chatMessage)
    }
    
    func onMessageUpdate(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        MEGALogInfo("ChatRoomDelegate: onMessageUpdate")
        message.chatId = self.chatRoom.chatId;
        print(message!.status)
        if message.hasChanged(for: .status) {
            switch message.status {
            case .unknown, .sending, .sendingManual:
                break
            case .serverReceived:
                let filteredArray = messages.filter { chatMessage in
                    return chatMessage.message.temporalId == message.temporalId
                }
              
                if filteredArray.count > 0 {
                    let oldMessage = filteredArray.first!
//                    if oldMessage.warningDialog.r > MEGAChatMessageWarningDialogNone {
//
//                    }
                    
                    let index = messages.firstIndex(of: oldMessage)!
                    let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                    messages[index] = receivedMessage
                    chatViewController.messagesCollectionView.performBatchUpdates({
                        chatViewController.messagesCollectionView.reloadSections([index])
                    }, completion: nil)
                    if message.type == .attachment {
                        
                    }
                } else {
                    message.chatId = chatRoom.chatId
                    insertMessage(message)
                }
                
            default:
                break
            }
        }
        
        if message.hasChanged(for: .content) {
            if message.isDeleted || message.isEdited {
                let filteredArray = messages.filter { chatMessage in
                    return chatMessage.message.messageId == message.messageId
                }
                if filteredArray.count > 0 {
                    let oldMessage = filteredArray.first!
                    
                    let index = messages.firstIndex(of: oldMessage)!
                    let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                    
                    if message.isEdited {
                        messages[index] = receivedMessage
                        chatViewController.messagesCollectionView.performBatchUpdates({
                            chatViewController.messagesCollectionView.reloadSections([index])
                        }, completion: nil)
                    }
                    
                    if message.isDeleted {
                        messages.remove(at: index)
                        chatViewController.messagesCollectionView.performBatchUpdates({
                            chatViewController.messagesCollectionView.deleteSections([index])
                        }, completion: nil)
                    }
                    
                }
            }
        }
    }
    
    func onHistoryReloaded(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        MEGALogInfo("ChatRoomDelegate: onHistoryReloaded")
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
    
    
    func insertMessage(_ message: MEGAChatMessage) {
         messages.append(ChatMessage(message: message, chatRoom: chatRoom))
        
         chatViewController.messagesCollectionView.performBatchUpdates({
             chatViewController.messagesCollectionView.insertSections([messages.count - 1])
         }, completion: { [weak self] _ in
             if self?.isLastSectionVisible() == true {
                 self?.chatViewController.messagesCollectionView.scrollToBottom(animated: true)
             }
         })
     }
    
    // MARK: - Private methods

    private func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return chatViewController.messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
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
