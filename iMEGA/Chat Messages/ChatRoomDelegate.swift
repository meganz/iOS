

import Foundation
import MessageKit

class ChatRoomDelegate: NSObject, MEGAChatRoomDelegate {
    
    // MARK: - Properties

    var chatRoom: MEGAChatRoom
    weak var chatViewController: ChatViewController?
    var chatMessages: [MessageType] = []
    var messages : [MessageType] {
        get {
          return  chatMessages
        }
    }
    var isChatRoomOpen: Bool = false
    var historyMessages: [ChatMessage] = []
    var loadingState = true
    private(set) var hasChatRoomClosed: Bool = false
    var isFullChatHistoryLoaded: Bool {
        return MEGASdkManager.sharedMEGAChatSdk()!.isFullHistoryLoaded(forChat: chatRoom.chatId)
    }
    
    var whoIsTyping: [UInt64: Timer] = [:]
    var awaitingLoad = false

    // MARK: - Init

    init(chatRoom: MEGAChatRoom?, chatViewController: ChatViewController?) {
        guard let chatRoom = chatRoom, let chatViewController = chatViewController else {
            self.chatRoom = MEGAChatRoom()
            super.init()
            return
        }
        self.chatRoom = chatRoom
        self.chatViewController = chatViewController
        super.init()
        MEGASdkManager.sharedMEGASdk()?.add(self)
        
        reloadTransferData()

    }
    
    // MARK: - MEGAChatRoomDelegate methods

    func onReactionUpdate(_ api: MEGAChatSdk!, messageId: UInt64, reaction: String!, count: Int) {
        
        guard let index = messages.firstIndex(where: { (message) -> Bool in
            guard let message = message as? ChatMessage else {
                return false
            }
            
            return messageId == message.message.messageId
        }),
            let numberOfSections = chatViewController?.messagesCollectionView.numberOfSections,
            numberOfSections > index else {
                return
        }
        UIView.performWithoutAnimation {
            chatViewController?.messagesCollectionView.performBatchUpdates({
                chatViewController?.messagesCollectionView.reloadSections([index])
            },  completion: { _ in
                if index == self.messages.count - 1 {
                    self.chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
                }
            })
        }
        
    }
    
    func onChatRoomUpdate(_ api: MEGAChatSdk!, chat: MEGAChatRoom!) {
        MEGALogInfo("ChatRoomDelegate: onChatRoomUpdate \(chatRoom)")
        chatViewController?.chatRoom = chat
        chatRoom = chat
        switch chat.changes {
        case .participants:
            if UIApplication.mnz_visibleViewController() == chatViewController {
                chatViewController?.reloadInputViews()
            }
        case .userTyping:
            guard !(chatViewController?.isEditing ?? false)  else {
                return
            }
            
            if (chat.userTypingHandle != api.myUserHandle) {
                if let timer = whoIsTyping[chat.userTypingHandle] {
                    timer.invalidate()
                }
                
                let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.removeTypingIndicator(forHandle: chat.userTypingHandle)
                }
                
                whoIsTyping[chat.userTypingHandle] = timer
                updateTypingIndicator()
            }
        case .userStopTyping:
            if chat.userTypingHandle != api.myUserHandle {
                removeTypingIndicator(forHandle: chat.userTypingHandle)
            }
            
        case .closed:
            hasChatRoomClosed = true
            if chatRoom.isPreview {
                api.closeChatPreview(chat.chatId)
                chatViewController?.reloadInputViews()
                let statusString = AMLocalizedString("linkRemoved",
                                                     "Message shown when the link to a file or folder has been removed")
                chatViewController?.updateJoinView()
                SVProgressHUD.showInfo(withStatus: statusString)
            } else {
                api.closeChatRoom(chat.chatId, delegate: self)
                chatViewController?.navigationController?.popViewController(animated: true)
            }
        case .updatePreviewers:
            chatViewController?.previewerView.isHidden = chatRoom.previewersCount == 0
            chatViewController?.previewerView.previewersLabel.text = "\(chatRoom.previewersCount)"
            chatViewController?.updateJoinView()
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
            
            if message.userHandle != api.myUserHandle, let chatViewController = chatViewController, !chatViewController.previewMode {
                api.setMessageSeenForChat(chatRoom.chatId, messageId: message.messageId)
            }
        } else {
            awaitingLoad = false
            if chatMessages.count == 0 {
                loadingState = false
                
                self.chatMessages = self.historyMessages
                self.historyMessages.removeAll()
                
                if chatRoom.unreadCount > 0,
                    chatMessages.count >= chatRoom.unreadCount,
                    let lastMessageId = (chatMessages.last as? ChatMessage)?.message.messageId, let chatViewController = chatViewController {
                    chatMessages.insert(ChatNotificationMessage(type: .unreadMessage(chatRoom.unreadCount)),
                                       at: chatMessages.count - chatRoom.unreadCount)
                    if !chatViewController.previewMode {
                        MEGASdkManager.sharedMEGAChatSdk()!.setMessageSeenForChat(chatRoom.chatId, messageId: lastMessageId)
                    }
                }
                
                self.chatViewController?.messagesCollectionView.reloadData()
                self.chatViewController?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
                self.chatViewController?.messagesCollectionView.scrollToBottom(animated: false)

                return
            }
            
            chatMessages = historyMessages + chatMessages
            historyMessages.removeAll()
            
            chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
            chatViewController?.showOrHideJumpToBottom()
            loadingState = false
        }
    }
    
    func onMessageReceived(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        MEGALogInfo("ChatRoomDelegate: onMessageReceived")

        guard let chatMessage = message else {
            MEGALogError("ChatRoomDelegate: onMessageReceived - message is nil")
            return
        }
        if UIApplication.shared.applicationState == .active,
            UIApplication.mnz_visibleViewController() == chatViewController,
            let chatViewController = chatViewController,
            !chatViewController.previewMode {
            MEGASdkManager.sharedMEGAChatSdk()?.setMessageSeenForChat(chatRoom.chatId, messageId: message.messageId)
        } else {
            chatRoom = api.chatRoom(forChatId: chatRoom.chatId)
        }
        
        if message.type == .truncate {
            chatMessages.removeAll()
            chatViewController?.messagesCollectionView.reloadData()
            
        }
        insertMessage(chatMessage)

    }
    
    func onMessageUpdate(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        MEGALogInfo("ChatRoomDelegate: onMessageUpdate")
        message.chatId = self.chatRoom.chatId
        if message.hasChanged(for: .status) {
            switch message.status {
            case .unknown, .sending, .sendingManual:
                break
            case .serverReceived:
                let filteredArray = chatMessages.filter { chatMessage in
                    guard let localChatMessage = chatMessage as? ChatMessage else {
                        return false
                    }
                    
                    return localChatMessage.message.temporalId == message.temporalId
                }
                
                if filteredArray.count > 0 {
                    guard let oldMessage = filteredArray.first as? ChatMessage,
                        let index = chatMessages.firstIndex(where: { message -> Bool in
                        guard let localChatMessage = message as? ChatMessage else {
                            return false
                        }
                        
                        return localChatMessage == oldMessage
                    }) else {
                        return
                    }
                    
                    let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                    chatMessages[index] = receivedMessage
                    chatViewController?.messagesCollectionView.performBatchUpdates({
                        chatViewController?.messagesCollectionView.reloadSections([index])
                    }, completion: nil)
                } else {
                    if message.type == .attachment || message.type == .voiceClip {
                        let filteredArray = chatMessages.filter { chatMessage in
                            guard let chatMessage = chatMessage as? ChatMessage, let nodeList = message.nodeList, let node = nodeList.node(at: 0) else { return false }
                            return node.handle == chatMessage.transfer?.nodeHandle
                        }
                        
                        if filteredArray.count > 0, let oldMessage = filteredArray.first as? ChatMessage {
                            let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                            chatMessages = chatMessages.map({ (message) -> MessageType in
                                guard let message = message as? ChatMessage, message != oldMessage else {
                                    return receivedMessage
                                }
                                return message
                                
                            })
                            if let transfer = oldMessage.transfer, let node = MEGASdkManager.sharedMEGASdk()?.node(forHandle: transfer.nodeHandle) {
                                let path = NSHomeDirectory().append(pathComponent: transfer.path)
                                let originalImagePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "originalV3")
                                try? FileManager.default.copyItem(atPath: path, toPath: originalImagePath)

                                                          
                            }
                            
                            
                            chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
                            chatViewController?.showOrHideJumpToBottom()
                            return
                        }
                    }

                    
                    message.chatId = chatRoom.chatId
                    insertMessage(message)
                }
                
            default:
                break
            }
        }
        
        if message.hasChanged(for: .content) {
            if message.isDeleted || message.isEdited {
                let filteredArray = chatMessages.filter { chatMessage in
                    guard let localChatMessage = chatMessage as? ChatMessage else  {
                        return false
                    }
                    
                    return localChatMessage.message.messageId == message.messageId
                }
                if filteredArray.count > 0 {
                    guard let oldMessage = filteredArray.first as? ChatMessage,
                        let index = chatMessages.firstIndex(where: { chatMessage -> Bool in
                            guard let localChatMessage = chatMessage as? ChatMessage else {
                                return false
                            }
                            
                            return localChatMessage == oldMessage
                        })else {
                            return
                    }
                    
                    let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                    
                    if message.isEdited {
                        chatMessages[index] = receivedMessage
                        chatViewController?.messagesCollectionView.performBatchUpdates({
                            chatViewController?.messagesCollectionView.reloadSections([index])
                            if isLastSectionVisible() {
                                chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
                            }
                        }, completion: nil)
                    }
                    
                    if message.isDeleted {
                        chatMessages.remove(at: index)
                        chatViewController?.messagesCollectionView.performBatchUpdates({
                            chatViewController?.messagesCollectionView.deleteSections([index])
                        }, completion: nil)
                    }
                    

                }
            }
            
            if message.type == .truncate {
                chatMessages.removeAll()
                chatViewController?.messagesCollectionView.reloadData()
                
                insertMessage(message)
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
    
    func updateUnreadMessagesLabel(unreads: Int) {
        let index = messages.firstIndex { object -> Bool in
            guard object is ChatNotificationMessage else {
                return false
            }
            
            return true
        }
        if let index = index {
            if unreads == 0 {
                chatMessages.remove(at: index)
                chatViewController?.messagesCollectionView.deleteSections([index])
                return
            }
            chatMessages[index] = ChatNotificationMessage(type: .unreadMessage(unreads))
            chatViewController?.messagesCollectionView.reloadSections([index])
        }
    }
    
    func insertMessage(_ message: MEGAChatMessage, scrollToBottom: Bool = false) {
        guard let messagesCollectionView = chatViewController?.messagesCollectionView else {
            return
        }
        if let historyMessageIndex = chatMessages.firstIndex(where: { historyMessage -> Bool in
            guard let historyMessage = historyMessage as? ChatMessage else {
                return false
            }
            return historyMessage.message.messageId == message.messageId
        }) {
            chatMessages[historyMessageIndex] = ChatMessage(message: message, chatRoom: chatRoom)
            messagesCollectionView.reloadSections([historyMessageIndex])
            return
        }
        
        
        let lastSectionVisible = isLastSectionVisible()
        let unreads = MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle == message.userHandle ? 0 : chatRoom.unreadCount
        var unreadNotificationMessageIndex: Int?

        let index = chatMessages.firstIndex { object -> Bool in
            guard object is ChatNotificationMessage else {
                return false
            }
            return true
        }
        
        if let index = index,
            let notificationMessage = chatMessages[index] as? ChatNotificationMessage,
            case .unreadMessage(let count) = notificationMessage.type {
            chatMessages[index] = ChatNotificationMessage(type: .unreadMessage(count + 1))
            unreadNotificationMessageIndex = index
        } else if UIApplication.shared.applicationState != .active
            || UIApplication.mnz_visibleViewController() != chatViewController {
            if MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle != message.userHandle {
                chatMessages.append(ChatNotificationMessage(type: .unreadMessage(unreads)))
                unreadNotificationMessageIndex = chatMessages.count - 1
            }
        }
        
        chatMessages.append(ChatMessage(message: message, chatRoom: chatRoom))

        if chatMessages.count == 1 {
            messagesCollectionView.reloadData()
            if chatViewController?.keyboardVisible ?? false {
                chatViewController?.additionalBottomInset = 0
            }
            messagesCollectionView.scrollToBottom(animated: true)
            return
        }
        UIView.setAnimationsEnabled(false)
        messagesCollectionView.performBatchUpdates({
            if let notificationMessageIndex = unreadNotificationMessageIndex {
                if notificationMessageIndex == chatMessages.count - 2 {
                    messagesCollectionView.insertSections([chatMessages.count - 2, chatMessages.count - 1])
                    if chatMessages.count >= 3 {
                        messagesCollectionView.reloadSections([chatMessages.count - 3])
                    }
                } else {
                    messagesCollectionView.insertSections([chatMessages.count - 1])
                    if chatMessages.count >= 3 {
                        messagesCollectionView.reloadSections([chatMessages.count - 3, chatMessages.count - 2, notificationMessageIndex])
                    } else {
                        messagesCollectionView.reloadSections([notificationMessageIndex])
                    }
                }
            } else {
                messagesCollectionView.insertSections([chatMessages.count - 1])
                if chatMessages.count >= 2 {
                    messagesCollectionView.reloadSections([chatMessages.count - 2])
                }
            }
        }, completion: { [weak self] _ in
            UIView.setAnimationsEnabled(true)
            if lastSectionVisible || scrollToBottom {
                self?.chatViewController?.messagesCollectionView.scrollToBottom(animated: true)
            } else {
                self?.chatViewController?.showNewMessagesToJumpToBottomIfRequired()
            }
        })
    }
    
    func insertTransfer(_ transer: MEGATransfer) {
        chatMessages.append(ChatMessage(transfer: transer, chatRoom: chatRoom))
        guard let chatViewController = self.chatViewController else { return }
        if messages.count == 1 {
            chatViewController.messagesCollectionView.reloadData()
            if chatViewController.keyboardVisible {
                chatViewController.additionalBottomInset = 0
            }
            chatViewController.messagesCollectionView.scrollToBottom(animated: true)
            return
        }
        chatViewController.messagesCollectionView.reloadData()
        chatViewController.messagesCollectionView.scrollToBottom(animated: true)
     }
    
    // MARK: - Private methods

    private func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return true }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return chatViewController?.messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath) ?? false
    }
    
    private func loadMessages(count: Int = 32) {
        if awaitingLoad {
            MEGALogWarning("[Chat Links Scalability] avoid loadMessages because of an ongoing load")
            return
        }
        switch MEGASdkManager.sharedMEGAChatSdk()!.loadMessages(forChat: chatRoom.chatId, count: count){
        case .error:
            MEGALogDebug("loadMessagesForChat: history has to be fetched from server, but we are not logged in yet")
        case .none:
            MEGALogDebug("loadMessagesForChat: there's no more history available (not even in the server)")
            awaitingLoad = true
        case .local:
            MEGALogDebug("loadMessagesForChat: messages will be fetched locally")
            awaitingLoad = true
        case .remote:
            MEGALogDebug("loadMessagesForChat: messages will be requested to the server")
            awaitingLoad = true
        @unknown default:
            MEGALogError("loadMessagesForChat: unknown case executed")
        }
    }
    
    private func reloadTransferData() {
        guard let allTransfers: [MEGATransfer] = MEGASdkManager.sharedMEGASdk()?.transfers.mnz_transfersArrayFromTranferList() else {
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
                            return true
                        }
                        
                    }
                }
            }
            return false
        }
        
        self.chatMessages = transfers.map({ (transfer) -> ChatMessage in
            return ChatMessage(transfer: transfer, chatRoom: chatRoom)
        })
    }
    
    private func updateTypingIndicator() {
        if whoIsTyping.keys.count >= 2 {
            updateTwoOrMoreUserTyping()
        } else if whoIsTyping.keys.count == 1 {
            if let handle = whoIsTyping.keys.first,
                let username = username(forHandle: handle) {
                let localizedString = AMLocalizedString("isTyping", "A typing indicator in the chat. Please leave the %@ which will be automatically replaced with the user's name at runtime.")
                let typingIndicatorString = String(format: localizedString, username)
                let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10, weight: .medium)]
                let typingIndicatorAttributedString = NSMutableAttributedString(string: typingIndicatorString,
                                                                                attributes: attributes)
                typingIndicatorAttributedString.addAttribute(NSAttributedString.Key.font,
                                                             value: UIFont.boldSystemFont(ofSize: 10),
                                                             range: NSMakeRange(0, username.utf16.count))
                chatViewController?.updateTypingIndicatorView(withAttributedString: typingIndicatorAttributedString)
            } else {
                MEGALogInfo("Either the handle or the username is not found")
            }
        } else {
            chatViewController?.updateTypingIndicatorView(withAttributedString: nil)
        }
    }
    
    private func updateTwoOrMoreUserTyping() {
        guard whoIsTyping.keys.count >= 2 else {
            fatalError("There should be two or more users typing for this method to be invoked")
        }
        
        let keys = Array(whoIsTyping.keys)
        let firstUserHandle = keys[0]
        let secondUserHandle = keys[1]
        
        if let firstUsername = username(forHandle: firstUserHandle),
            let secondUsername = username(forHandle: secondUserHandle) {
            let combinedUsername = "\(firstUsername) , \(secondUsername)"
            
            let localizedString: String?
            if keys.count > 2 {
                localizedString = AMLocalizedString("moreThanTwoUsersAreTyping", "text that appear when there are more than 2 people writing at that time in a chat. For example User1, user2 and more are typing... The parameter will be the concatenation of the first two user names. Please do not translate or modify the tags or placeholders.").mnz_removeWebclientFormatters()
            } else {
                localizedString = AMLocalizedString("twoUsersAreTyping", "Plural, a hint that appears when two users are typing in a group chat at the same time. The parameter will be the concatenation of both user names. Please do not translate or modify the tags or placeholders.").mnz_removeWebclientFormatters()
            }
            
            if let typingIndicatorString = localizedString?.replacingOccurrences(of: "%1$s", with: combinedUsername) {
                let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10, weight: .medium)]
                let typingIndicatorAttributedString = NSMutableAttributedString(string: typingIndicatorString,
                                                                                attributes: attributes)
                typingIndicatorAttributedString.addAttribute(NSAttributedString.Key.font,
                                                             value: UIFont.boldSystemFont(ofSize: 10),
                                                             range: NSMakeRange(0, typingIndicatorString.utf16.count))
                chatViewController?.updateTypingIndicatorView(withAttributedString: typingIndicatorAttributedString)
            }
        }
    }
    
    private func removeTypingIndicator(forHandle handle: UInt64) {
        whoIsTyping[handle] = nil
        updateTypingIndicator()
    }
    
    private func username(forHandle handle: UInt64) -> String? {
        if let userNickname = chatRoom.userNickname(forUserHandle: handle) {
            return userNickname
        } else if let userFirstName = chatRoom.participantName(forUserHandle: handle) {
            return userFirstName
        }
        return nil
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
            chatMessages = chatMessages.map({ (chatMessage) -> MessageType in
                
                if  let chatMessage = chatMessage as? ChatMessage, chatMessage.transfer?.tag == transfer.tag {
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
            chatMessages = chatMessages.map({ (chatMessage) -> MessageType in
                
                if  let chatMessage = chatMessage as? ChatMessage, chatMessage.transfer?.tag == transfer.tag {
                    return ChatMessage(transfer: transfer, chatRoom: chatRoom)
                }
                
                return chatMessage
                
            })
            
        }        
    }
    
    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        
    }
}
