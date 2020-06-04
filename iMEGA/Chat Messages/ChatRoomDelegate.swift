

import Foundation
import MessageKit

class ChatRoomDelegate: NSObject, MEGAChatRoomDelegate {
    
    // MARK: - Properties

    var transfers: [ChatMessage] = []
    let chatRoom: MEGAChatRoom
    weak var chatViewController: ChatViewController?
    var chatMessage: [ChatMessage] = []
    var messages : [ChatMessage] {
        get {
          return  chatMessage + transfers
        }
    }
    var isChatRoomOpen: Bool = false
    var historyMessages: [ChatMessage] = []
    var loadingState = true
    private(set) var hasChatRoomClosed: Bool = false
    var isFullChatHistoryLoaded: Bool {
        return MEGASdkManager.sharedMEGAChatSdk()!.isFullHistoryLoaded(forChat: chatRoom.chatId)
    }
    
    // MARK: - Init

    init(chatRoom: MEGAChatRoom, chatViewController: ChatViewController) {
        self.chatRoom = chatRoom
        self.chatViewController = chatViewController
        super.init()
        MEGASdkManager.sharedMEGASdk()?.add(self)
        
        reloadTransferData()

    }
    
    // MARK: - MEGAChatRoomDelegate methods

    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        MEGALogInfo("ChatRoomDelegate: onChatRoomUpdate \(chatRoom)")
        chatViewController?.chatRoom = chat
        
        switch chat.changes {
        case .userTyping:
            guard !(chatViewController?.isEditing ?? false)  else {
                return
            }
            
            if (chat.userTypingHandle != api.myUserHandle) {
                chatViewController?.setTypingIndicatorViewHidden(false, animated: true ,whilePerforming: nil) { [weak self] success in
                    if success, self?.isLastSectionVisible() == true {
                        self?.chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
                    }
                }
            }
        case .userStopTyping:
            chatViewController?.setTypingIndicatorViewHidden(true, animated: true ,whilePerforming: nil)  { [weak self] success in
                if success, self?.isLastSectionVisible() == true {
                    self?.chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
                }
            }
        case .closed:
            hasChatRoomClosed = true
            if chatRoom.isPreview {
                api.closeChatPreview(chat.chatId)
                chatViewController?.reloadInputViews()
                let statusString = AMLocalizedString("linkRemoved",
                                                     "Message shown when the link to a file or folder has been removed")
                SVProgressHUD.showInfo(withStatus: statusString)
            }
        case .updatePreviewers:
            chatViewController?.previewerView.isHidden = chatRoom.previewersCount == 0
            chatViewController?.previewerView.previewersLabel.text = "\(chatRoom.previewersCount)"
        default:
            break
        }
    }
    
    func onMessageLoaded(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        MEGALogInfo("ChatRoomDelegate: onMessageLoaded")
        
        
        if let chatMessage = message {
            if !chatMessage.isDeleted {
                if chatMessage.status == .sending || chatMessage.status == .sendingManual {
                    historyMessages.append(ChatMessage(message: chatMessage, chatRoom: chatRoom))
                } else {
                    historyMessages.insert(ChatMessage(message: chatMessage, chatRoom: chatRoom), at: 0)
                }
            }
        } else {

            if chatMessage.count == 0 {
                chatMessage = historyMessages
                historyMessages.removeAll()
                chatViewController?.messagesCollectionView.reloadData()
                chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
                loadingState = false

                return
            }
            
            chatMessage = historyMessages + chatMessage
            historyMessages.removeAll()
            
            if (loadingState) {
                chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
            } else {
                chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
            }
            
            loadingState = false
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
                reloadTransferData()
                let filteredArray = chatMessage.filter { chatMessage in
                    return chatMessage.message.temporalId == message.temporalId
                }
                
                if filteredArray.count > 0 {
                    let oldMessage = filteredArray.first!
                    //                    if oldMessage.warningDialog.r > MEGAChatMessageWarningDialogNone {
//
//                    }
                    
                    let index = chatMessage.firstIndex(of: oldMessage)!
                    let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                    chatMessage[index] = receivedMessage
                    chatViewController?.messagesCollectionView.performBatchUpdates({
                        chatViewController?.messagesCollectionView.reloadSections([index])
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
                let filteredArray = chatMessage.filter { chatMessage in
                    return chatMessage.message.messageId == message.messageId
                }
                if filteredArray.count > 0 {
                    let oldMessage = filteredArray.first!
                    
                    let index = chatMessage.firstIndex(of: oldMessage)!
                    let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                    
                    if message.isEdited {
                        chatMessage[index] = receivedMessage
                        chatViewController?.messagesCollectionView.performBatchUpdates({
                            chatViewController?.messagesCollectionView.reloadSections([index])
                        }, completion: nil)
                    }
                    
                    if message.isDeleted {
                        chatMessage.remove(at: index)
                        chatViewController?.messagesCollectionView.performBatchUpdates({
                            chatViewController?.messagesCollectionView.deleteSections([index])
                        }, completion: nil)
                    }
                    
                }
            }
        }
        chatViewController?.messagesCollectionView.reloadEmptyDataSet()
    }
    
    func onHistoryReloaded(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        MEGALogInfo("ChatRoomDelegate: onHistoryReloaded")
    }
    
    // MARK: - Interface methods

    func loadMoreMessages() {
        if !isFullChatHistoryLoaded {
            loadingState = true
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
        let lastSectionVisible = isLastSectionVisible()
        chatMessage.append(ChatMessage(message: message, chatRoom: chatRoom))
        
        if chatMessage.count == 1 {
            chatViewController?.messagesCollectionView.reloadData()
            if chatViewController?.keyboardVisible ?? false {
                chatViewController?.additionalBottomInset = 0
                chatViewController?.messagesCollectionView.scrollToLastItem()
            }
            return;
        }
        chatViewController?.messagesCollectionView.reloadData()
        if lastSectionVisible == true {
            chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
    
    func insertTransfer(_ transer: MEGATransfer) {
        let lastSectionVisible = isLastSectionVisible()
        transfers.append(ChatMessage(transfer: transer, chatRoom: chatRoom))
        guard let chatViewController = self.chatViewController else { return }
        if messages.count == 1 {
            chatViewController.messagesCollectionView.reloadData()
            if chatViewController.keyboardVisible {
                chatViewController.additionalBottomInset = 0
                chatViewController.messagesCollectionView.scrollToBottom()
            }
            return;
        }
        chatViewController.messagesCollectionView.reloadData()
        if lastSectionVisible == true {
            chatViewController.messagesCollectionView.scrollToBottom(animated: true)
        }
     }
    
    // MARK: - Private methods

    private func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return chatViewController?.messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath) ?? false
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
    
    private func reloadTransferData() {
        guard let allTransfers: [MEGATransfer] =         MEGASdkManager.sharedMEGASdk()?.transfers.mnz_transfersArrayFromTranferList() else {
            return
        }
        let transfers = allTransfers.filter { (transfer) -> Bool in

            guard let appData = transfer.appData,
                   appData.contains("attachToChatID")
                || appData.contains("attachVoiceClipToChatID") else {
                    return false
            }
            let appDataComponentsArray = transfer.appData.components(separatedBy: ">")
            if appDataComponentsArray.count > 0 {
                for appDataComponent in appDataComponentsArray {
                    let appDataComponentComponentsArray = appDataComponent.components(separatedBy: "=")
                    guard let appDataType = appDataComponentComponentsArray.first else {
                        return false
                    }
                    if appDataType == "attachToChatID"
                        || appDataType == "attachVoiceClipToChatID" {
                        let tempAppDataComponent = appDataComponent.replacingOccurrences(of: "!", with: "")
                        guard let chatID = tempAppDataComponent.components(separatedBy: "=").last else {
                            return false
                        }
                        if UInt64(chatID) == chatRoom.chatId {
//                            insertTransfer(transfer)
                            return true
                        }
                        
                    }
                }
            }
            return false
        }
        
        self.transfers = transfers.map({ (transfer) -> ChatMessage in
            return ChatMessage(transfer: transfer, chatRoom: chatRoom)
        })
//        guard transfers.count > 0 else {
//            return
//        }
//        chatViewController.messagesCollectionView.reloadEmptyDataSet()
    }
}

extension ChatRoomDelegate: MEGATransferDelegate {
    // MARK: - MEGATransferDelegate methods
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        guard let appData = transfer.appData else {
            return
        }
        if appData.contains("\(chatRoom.chatId)") {
            insertTransfer(transfer)
        }
    }
    
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        guard let appData = transfer.appData else {
            return
        }
        if appData.contains("\(chatRoom.chatId)") {
            transfers = transfers.map({ (chatMessage) -> ChatMessage in
                if chatMessage.transfer?.tag == transfer.tag {
                    return ChatMessage(transfer: transfer, chatRoom: chatRoom)
                }
                
                return chatMessage
                
            })
            
        }
        
    }
    
    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        guard let appData = transfer.appData else {
            return
        }
        if appData.contains("\(chatRoom.chatId)") {
            transfers = transfers.map({ (chatMessage) -> ChatMessage in
                if chatMessage.transfer?.tag == transfer.tag {
                    return ChatMessage(transfer: transfer, chatRoom: chatRoom)
                }
                
                return chatMessage
                
            })
            
        }
        
        print(transfer.tag)
    }
    
    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        
    }
}
