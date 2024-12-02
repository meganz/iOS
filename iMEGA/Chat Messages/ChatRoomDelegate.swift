import ChatRepo
import Foundation
import MEGADomain
import MEGAL10n
import MessageKit

@MainActor
final class ChatRoomDelegate: NSObject, MEGAChatRoomDelegate, MEGAChatRequestDelegate {
    // MARK: - Properties
    
    private var transfers: [ChatMessage] = []
    private var chatRoom: ChatRoomEntity
    weak var chatViewController: ChatViewController?
    var chatMessages: [any MessageType] = []
    var messages: [any MessageType] {
        return chatMessages + transfers
    }
    
    private var isChatRoomOpen: Bool = false
    private var historyMessages: [ChatMessage] = []
    var loadingState = true
    private(set) var hasChatRoomClosed: Bool = false
    var isFullChatHistoryLoaded: Bool {
        return MEGAChatSdk.shared.isFullHistoryLoaded(forChat: chatRoom.chatId)
    }
    
    private var whoIsTyping: [UInt64: Timer] = [:]
    private var awaitingLoad = false
    
    // MARK: - Init
    
    init(chatRoom: ChatRoomEntity) {
        self.chatRoom = chatRoom
        super.init()
    }
    
    // MARK: - MEGAChatRequestDelegate
    
    nonisolated func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        switch error.type {
        case .MEGAChatErrorTooMany:
            switch ReactionErrorType(rawValue: Int(request.number)) {
            case .user:
                let title = Strings.Localizable.youHaveReachedTheMaximumLimitOfDReactions(MEGAMaxReactionsPerMessagePerUser)
                Task {
                    await presentAlertController(title: title)
                }
            case .message:
                let title = String(format: Strings.Localizable.thisMessageHasReachedTheMaximumLimitOfDReactions(MEGAMaxReactionsPerMessage))
                Task {
                    await presentAlertController(title: title)
                }
            default:
                break
            }
            
        default:
            break
        }
    }
    
    // MARK: - MEGAChatRoomDelegate methods
    
    nonisolated func onReactionUpdate(_: MEGAChatSdk, messageId: UInt64, reaction _: String, count _: Int) {
        Task { @MainActor in
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
                }, completion: { _ in
                    if index == self.messages.count - 1 {
                        self.chatViewController?.scrollToBottom()
                    }
                })
            }
        }
    }
    
    nonisolated func onChatRoomUpdate(_ api: MEGAChatSdk, chat: MEGAChatRoom) {
        Task { @MainActor in
            MEGALogInfo("ChatRoomDelegate: onChatRoomUpdate \(chatRoom)")
            
            chatViewController?.update(chatRoom: chat.toChatRoomEntity())
            chatRoom = chat.toChatRoomEntity()
            
            switch chat.changes {
            case .participants:
                if UIApplication.mnz_visibleViewController() == chatViewController {
                    chatViewController?.reloadInputViews()
                }
            case .userTyping:
                guard !(chatViewController?.isEditing ?? false) else {
                    return
                }
                
                if chat.userTypingHandle != api.myUserHandle {
                    if let timer = whoIsTyping[chat.userTypingHandle] {
                        timer.invalidate()
                    }
                    
                    let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                        guard let self else { return }
                        Task { @MainActor in
                            self.removeTypingIndicator(forHandle: chat.userTypingHandle)
                        }

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
                    chatViewController?.updateJoinView()
                    SVProgressHUD.showInfo(withStatus: Strings.Localizable.Chat.Link.linkRemoved)
                } else {
                    let chatRoomRepository = ChatRoomRepository.newRepo
                    guard let chatRoom = chatRoomRepository.chatRoom(forChatId: chat.chatId) else { return }
                    chatRoomRepository.closeChatRoom(chatRoom, delegate: ChatRoomDelegateEntity())
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
    }
    
    nonisolated func onMessageLoaded(_ api: MEGAChatSdk, message: MEGAChatMessage?) {
        Task { @MainActor in
            guard include(message: message) else { return }
            
            if let chatMessage = message {
                if !chatMessage.isDeleted {
                    if supportedMessage(chatMessage) && !isDuplicateMessage(chatMessage) {
                        if chatMessage.status == .sending || chatMessage.status == .sendingManual {
                            historyMessages.append(ChatMessage(message: chatMessage, chatRoom: chatRoom))
                        } else {
                            historyMessages.insert(ChatMessage(message: chatMessage, chatRoom: chatRoom), at: 0)
                        }
                    }
                }
                
                if chatMessage.userHandle != api.myUserHandle, let chatViewController = chatViewController, !chatViewController.previewMode {
                    api.setMessageSeenForChat(chatRoom.chatId, messageId: chatMessage.messageId)
                }
            } else {
                awaitingLoad = false
                if chatMessages.isEmpty {
                    loadingState = false
                    
                    chatMessages = historyMessages
                    historyMessages.removeAll()
                    
                    if chatRoom.unreadCount > 0,
                       chatMessages.count >= chatRoom.unreadCount,
                       let lastMessageId = (chatMessages.last as? ChatMessage)?.message.messageId, let chatViewController = chatViewController {
                        chatMessages.insert(ChatNotificationMessage(type: .unreadMessage(chatRoom.unreadCount)),
                                            at: chatMessages.count - chatRoom.unreadCount)
                        if !chatViewController.previewMode {
                            MEGAChatSdk.shared.setMessageSeenForChat(chatRoom.chatId, messageId: lastMessageId)
                        }
                        
                        chatViewController.messagesCollectionView.reloadData()
                        // 1 because the "unread text" notification cell should be shown as well.
                        let scrollingIndexPath = IndexPath(item: 0, section: chatMessages.count - chatRoom.unreadCount - 1)
                        chatViewController.messagesCollectionView.scrollToItem(at: scrollingIndexPath,
                                                                               at: .top,
                                                                               animated: false)
                        
                        return
                    }
                    
                    chatViewController?.messagesCollectionView.reloadData()
                    chatViewController?.scrollToBottom(animated: false)
                    return
                }
                
                chatMessages = historyMessages + chatMessages
                historyMessages.removeAll()
                
                chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
                chatViewController?.showOrHideJumpToBottom()
                loadingState = false
            }
        }
    }
    
    nonisolated func onMessageReceived(_ api: MEGAChatSdk, message: MEGAChatMessage) {
        Task { @MainActor in
            MEGALogInfo("ChatRoomDelegate: onMessageReceived \(message)")
            guard include(message: message) else { return }
            
            guard supportedMessage(message) else {
                MEGALogError("ChatRoomDelegate: onMessageReceived - message not supported")
                return
            }
            
            if UIApplication.shared.applicationState == .active,
               UIApplication.mnz_visibleViewController() == chatViewController,
               let chatViewController = chatViewController,
               !chatViewController.previewMode {
                api.setMessageSeenForChat(chatRoom.chatId, messageId: message.messageId)
            } else if let chatRoom = api.chatRoom(forChatId: chatRoom.chatId) {
                self.chatRoom = chatRoom.toChatRoomEntity()
            }
            
            if message.type == .truncate {
                chatMessages.removeAll()
                updateUnreadMessagesLabel(unreads: 0)
                chatViewController?.messagesCollectionView.reloadData()
            }
            
            // [MEET-522]
            // Loading user attributes here, so that later when rendering the message,
            // we always have first and last name to show. It's possible that upon receiving the message,
            // SDK returns nil in `getUserFullnameFromCache`
            let userHandles = [
                NSNumber(value: message.userHandle)
            ]
            
            // if full name is nil, then loadUserAttributes, else just insert message
            guard api.userFullnameFromCache(byUserHandle: message.userHandle) == nil else {
                insertMessage(message)
                return
            }
            
            api.loadUserAttributes(
                forChatId: chatRoom.chatId,
                usersHandles: userHandles,
                delegate: ChatRequestDelegate(completion: {[weak self] _, _ in
                    self?.insertMessage(message)
                })
            )
        }
    }
    
    nonisolated func onMessageUpdate(_: MEGAChatSdk, message: MEGAChatMessage) {
        Task { @MainActor in
            MEGALogInfo("ChatRoomDelegate: onMessageUpdate")
            message.chatId = chatRoom.chatId
            handleStatusChanged(message)
            handleContentChanged(message)
            
            chatViewController?.messagesCollectionView.reloadEmptyDataSet()
        }
    }
    
    private func handleStatusChanged(_ message: MEGAChatMessage) {
        guard message.hasChanged(for: .status) else { return }
        
        if case .serverReceived = message.status {
            let filteredArray = chatMessages.filter { chatMessage in
                guard let localChatMessage = chatMessage as? ChatMessage else {
                    return false
                }
                
                return localChatMessage.message.temporalId == message.temporalId
            }
            
            if filteredArray.isNotEmpty {
                guard let oldMessage = filteredArray.first as? ChatMessage,
                      let index = chatMessages
                        
                    .firstIndex(where: { message -> Bool in
                          guard let localChatMessage = message as? ChatMessage else {
                              return false
                          }
                          
                          return localChatMessage == oldMessage
                      }) else {
                    return
                }
                message.warningDialog = oldMessage.message.warningDialog
                let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                chatMessages[index] = receivedMessage
                
                UIView.performWithoutAnimation {
                    chatViewController?.messagesCollectionView.performBatchUpdates({
                        chatViewController?.messagesCollectionView.reloadSections([index])
                    }, completion: { _ in
                        if index == self.messages.count - 1 {
                            self.chatViewController?.scrollToBottom()
                        }
                    })
                }
            } else {
                if message.type == .attachment || message.type == .voiceClip {
                    let filteredArray = transfers.filter { chatMessage in
                        guard let nodeList = message.nodeList, let node = nodeList.node(at: 0) else { return false }
                        return node.handle == chatMessage.transfer?.nodeHandle
                    }
                    
                    if filteredArray.isNotEmpty, let oldMessage = filteredArray.first, let index = transfers.firstIndex(of: oldMessage) {
                        let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                        chatMessages.append(receivedMessage)
                        transfers.remove(at: index)
                        if let transfer = oldMessage.transfer, let node = MEGASdk.shared.node(forHandle: transfer.nodeHandle), let transferPath = transfer.path {
                            let path = NSHomeDirectory().append(pathComponent: transferPath)
                            let originalImagePath = Helper.pathWithOriginalName(for: node, inSharedSandboxCacheDirectory: "originalV3")
                            try? FileManager.default.copyItem(atPath: path, toPath: originalImagePath)
                        }
                        
                        chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
                        if isLastSectionVisible() {
                            chatViewController?.scrollToBottom(animated: false)
                        }
                        chatViewController?.showOrHideJumpToBottom()
                        return
                    }
                }
                
                message.chatId = chatRoom.chatId
                insertMessage(message)
            }
        }
    }

    private func handleContentChanged(_ message: MEGAChatMessage) {
        guard message.hasChanged(for: .content) else { return }
        if message.isDeleted || message.isEdited {
            let filteredArray = chatMessages.filter { chatMessage in
                guard let localChatMessage = chatMessage as? ChatMessage else {
                    return false
                }
                
                return localChatMessage.message.messageId == message.messageId
            }
            if filteredArray.isNotEmpty {
                guard let oldMessage = filteredArray.first as? ChatMessage,
                      let index = chatMessages.firstIndex(where: { chatMessage -> Bool in
                          guard let localChatMessage = chatMessage as? ChatMessage else {
                              return false
                          }
                          
                          return localChatMessage == oldMessage
                      }) else {
                    return
                }
                
                let receivedMessage = ChatMessage(message: message, chatRoom: chatRoom)
                
                if message.isEdited {
                    chatMessages[index] = receivedMessage
                    chatViewController?.messagesCollectionView.performBatchUpdates({
                        chatViewController?.messagesCollectionView.reloadSections([index])
                        if isLastSectionVisible() {
                            chatViewController?.scrollToBottom()
                        }
                    }, completion: nil)
                }
                
                if message.isDeleted {
                    chatMessages.remove(at: index)
                    chatViewController?.messagesCollectionView.performBatchUpdates({
                        chatViewController?.messagesCollectionView.deleteSections([index])
                    }, completion: nil)
                    
                    let unreadNotiMessageIndex = chatMessages.firstIndex { $0 is ChatNotificationMessage }
                    if let unreadNotiMessageIndex = unreadNotiMessageIndex,
                       let notificationMessage = chatMessages[unreadNotiMessageIndex] as? ChatNotificationMessage,
                       case let .unreadMessage(count) = notificationMessage.type {
                        if unreadNotiMessageIndex < index {
                            chatMessages[unreadNotiMessageIndex] = ChatNotificationMessage(type: .unreadMessage(count - 1))
                            chatViewController?.messagesCollectionView.performBatchUpdates({
                                chatViewController?.messagesCollectionView.reloadSections([unreadNotiMessageIndex])
                            }, completion: nil)
                        }
                    }
                }
            }
        }
        
        if message.type == .truncate {
            updateUnreadMessagesLabel(unreads: 0)
            chatMessages.removeAll()
            chatViewController?.messagesCollectionView.reloadData()
            
            insertMessage(message)
        }
    }
    
    nonisolated func onHistoryReloaded(_: MEGAChatSdk, chat _: MEGAChatRoom) {
        MEGALogInfo("ChatRoomDelegate: onHistoryReloaded")
    }
    
    // MARK: - Interface methods
    
    func updateMessage(_ message: MEGAChatMessage) {
        let filteredArray = chatMessages.filter { chatMessage in
            guard let localChatMessage = chatMessage as? ChatMessage else {
                return false
            }
            
            return localChatMessage.message.temporalId == message.temporalId
        }
        
        if filteredArray.isNotEmpty {
            guard let oldMessage = filteredArray.first as? ChatMessage,
                  let index = chatMessages.firstIndex(where: { message -> Bool in
                      guard let localChatMessage = message as? ChatMessage else {
                          return false
                      }
                      
                      return localChatMessage == oldMessage
                  }) else {
                return
            }
            oldMessage.message.warningDialog = message.warningDialog
            chatMessages[index] = oldMessage
            
            chatViewController?.messagesCollectionView.performBatchUpdates({
                chatViewController?.messagesCollectionView.reloadSections([index])
            }, completion: { _ in
                if index == self.messages.count - 1 {
                    self.chatViewController?.scrollToBottom()
                }
            })
        }
    }
    
    func loadMoreMessages() {
        if !isFullChatHistoryLoaded {
            loadingState = true
            loadMessages()
        }
    }
    
    func openChatRoom() {
        guard isChatRoomOpen == false else {
            MEGALogDebug("openChatRoom: Trying to open already opened chat room - \(isChatRoomOpen)")
            return
        }
        
        resetChatRoom()
        
        Task {
            removeDelegates()
            
            MEGASdk.shared.add(self)
            MEGAChatSdk.shared.add(self)
            
            reloadTransferData()
            
            do {
                try ChatRoomRepository.newRepo.openChatRoom(chatId: chatRoom.chatId, delegate: self)
                isChatRoomOpen = true
                loadingState = true
                
                reloadEmptyDataSet()
                
                loadMessages()
            } catch {
                MEGALogError("OpenChatRoom: Cannot open chat room with id \(chatRoom.chatId)")
            }
        }
    }
    
    func removeDelegates() {
        MEGAChatSdk.shared.remove(self)
        MEGASdk.shared.remove(self)
    }
    
    func removeDelegatesAsync() {
        MEGAChatSdk.shared.removeMEGAChatRequestDelegateAsync(self)
        MEGASdk.shared.removeMEGATransferDelegateAsync(self)
    }
    
    func resetChatRoom() {
        isChatRoomOpen = false
        chatMessages = []
        chatViewController?.messagesCollectionView.reloadData()
        ChatRoomRepository.newRepo.closeChatRoom(chatId: chatRoom.chatId, delegate: self)
    }
    
    func updateUnreadMessagesLabel(unreads: Int) {
        let index = messages.firstIndex { $0 is ChatNotificationMessage }
        if let index = index {
            if unreads == 0 {
                chatMessages.remove(at: index)
            } else {
                chatMessages[index] = ChatNotificationMessage(type: .unreadMessage(unreads))
            }
            chatViewController?.messagesCollectionView.reloadData()
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
            if message.status == .sending || message.status == .sendingManual {
                return historyMessage.message.temporalId == message.temporalId
            }
            return historyMessage.message.messageId == message.messageId
        }) {
            chatMessages[historyMessageIndex] = ChatMessage(message: message, chatRoom: chatRoom)
            messagesCollectionView.reloadSections([historyMessageIndex])
            return
        }
        
        let lastSectionVisible = isLastSectionVisible()
        let unreads = MEGAChatSdk.shared.myUserHandle == message.userHandle ? 0 : chatRoom.unreadCount
        
        let index = chatMessages.firstIndex { $0 is ChatNotificationMessage }
        
        if let index = index,
           let notificationMessage = chatMessages[index] as? ChatNotificationMessage,
           case let .unreadMessage(count) = notificationMessage.type {
            chatMessages[index] = ChatNotificationMessage(type: .unreadMessage(count + 1))
        } else if UIApplication.shared.applicationState != .active
                    || UIApplication.mnz_visibleViewController() != chatViewController {
            if MEGAChatSdk.shared.myUserHandle != message.userHandle,
               unreads > 0 {
                chatMessages.append(ChatNotificationMessage(type: .unreadMessage(unreads)))
            }
        }
        
        chatMessages.append(ChatMessage(message: message, chatRoom: chatRoom))
        messagesCollectionView.reloadData()
        
        if chatMessages.count == 1 {
            if chatViewController?.keyboardVisible ?? false {
                chatViewController?.additionalBottomInset = 0
            }
            chatViewController?.scrollToBottom()
            return
        }
        
        if lastSectionVisible || scrollToBottom {
            chatViewController?.messagesCollectionView.scrollToItem(at: IndexPath(item: 0, section: self.chatMessages.count - 1), at: .bottom, animated: true)
        } else {
            self.chatViewController?.unreadNewMessagesCount += 1
            chatViewController?.showJumpToBottom()
        }
    }
    
    func insertTransfer(_ transer: MEGATransfer) {
        transfers.append(ChatMessage(transfer: transer, chatRoom: chatRoom))
        guard let chatViewController = self.chatViewController else { return }
        if messages.count == 1 {
            chatViewController.messagesCollectionView.reloadData()
            if chatViewController.keyboardVisible {
                chatViewController.additionalBottomInset = 0
            }
            chatViewController.scrollToBottom()
            return
        }
        chatViewController.messagesCollectionView.reloadData()
        chatViewController.scrollToBottom()
    }
    
    // MARK: - Private methods
    
    private func include(message: MEGAChatMessage?) -> Bool {
        // Remove the new meeting management message from chatroom.
        // This is because the information provided by SDK is interpreted wrongly by the app and hence filtering it for now.
        guard message?.messageIndex != -1 || message?.type != .scheduledMeeting else { return false }
        // Updating the meeting title requires to update the chat title as well.
        // So filter the message if the chatroom is meeting and the type is chat title.
        guard !chatRoom.isMeeting || message?.type != .chatTitle else { return false }
        
        return true
    }
    
    private func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return true }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return chatViewController?.messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath) ?? false
    }
    
    private func loadMessages(count: Int = 32) {
        if !isChatRoomOpen || awaitingLoad {
            MEGALogWarning("[Chat Links Scalability] avoid loadMessages because of an ongoing load")
            return
        }
        switch MEGAChatSdk.shared.loadMessages(forChat: chatRoom.chatId, count: count) {
        case .invalidChat:
            MEGALogError("loadMessagesForChat: not available chat with the given chatid")
        case .error:
            MEGALogError("loadMessagesForChat: history has to be fetched from server, but we are not logged in yet")
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
        let allTransfers = MEGASdk.shared.transfers.toTransfers()
        guard allTransfers.isNotEmpty else {
            return
        }
        chatViewController?.checkTransferPauseStatus()
        let transfers = allTransfers.filter { (transfer) -> Bool in
            
            guard 
                let appData = transfer.appData,
                appData.contains("attachToChatID") || appData.contains("attachVoiceClipToChatID") 
            else {
                return false
            }

            let appDataComponentsArray = appData.components(separatedBy: ">")
            if appDataComponentsArray.isNotEmpty {
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
        
        self.transfers = transfers.map { (transfer) -> ChatMessage in
            ChatMessage(transfer: transfer, chatRoom: chatRoom)
        }
    }
    
    private func updateTypingIndicator() {
        if whoIsTyping.keys.count >= 2 {
            updateTwoOrMoreUserTyping()
        } else if whoIsTyping.keys.count == 1 {
            if let handle = whoIsTyping.keys.first,
               let username = username(forHandle: handle) {
                let typingIndicatorString = Strings.Localizable.isTyping(username)
                let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(style: .caption2, weight: .medium)]
                let typingIndicatorAttributedString = NSMutableAttributedString(string: typingIndicatorString,
                                                                                attributes: attributes)
                typingIndicatorAttributedString.addAttribute(NSAttributedString.Key.font,
                                                             value: UIFont.preferredFont(style: .caption2, weight: .medium),
                                                             range: NSRange(location: 0, length: username.utf16.count))
                typingIndicatorAttributedString.addAttributes([NSAttributedString.Key.font: UIFont.preferredFont(style: .caption2, weight: .medium),
                                                               NSAttributedString.Key.foregroundColor: UIColor.label], range: NSRange(location: 0, length: username.utf16.count))
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
            let combinedUsername = "\(firstUsername), \(secondUsername)"
            
            let localizedString: String?
            if keys.count > 2 {
                localizedString = Strings.Localizable.moreThanTwoUsersAreTyping(combinedUsername).mnz_removeWebclientFormatters()
            } else {
                localizedString = Strings.Localizable.twoUsersAreTyping(combinedUsername).mnz_removeWebclientFormatters()
            }
            
            if let typingIndicatorString = localizedString {
                let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(style: .caption2, weight: .medium)]
                let typingIndicatorAttributedString = NSMutableAttributedString(string: typingIndicatorString,
                                                                                attributes: attributes)
                typingIndicatorAttributedString.addAttributes([NSAttributedString.Key.font: UIFont.preferredFont(style: .caption2, weight: .medium),
                                                               NSAttributedString.Key.foregroundColor: UIColor.label], range: NSRange(location: 0, length: combinedUsername.utf16.count))
                chatViewController?.updateTypingIndicatorView(withAttributedString: typingIndicatorAttributedString)
            }
        }
    }
    
    private func removeTypingIndicator(forHandle handle: UInt64) {
        whoIsTyping[handle] = nil
        updateTypingIndicator()
    }
    
    private func username(forHandle handle: UInt64) -> String? {
        if let userNickname = userNickname(forUserHandle: handle) {
            return userNickname
        } else if let userFirstName = participantName(forUserHandle: handle) {
            return userFirstName
        }
        return nil
    }
    
    private func supportedMessage(_ message: MEGAChatMessage) -> Bool {
        switch message.type {
        case .normal, .alterParticipants, .truncate, .privilegeChange, .chatTitle, .attachment, .contact,
                .callEnded, .callStarted, .containsMeta, .voiceClip, .publicHandleCreate, .publicHandleDelete,
                . setPrivateMode, .setRetentionTime, .scheduledMeeting:
            return true
        default:
            return false
        }
    }
    
    private func reloadEmptyDataSet() {
        chatViewController?.messagesCollectionView.reloadEmptyDataSet()
    }
    
    private func isDuplicateMessage(_ message: MEGAChatMessage) -> Bool {
        if let lastMessageId = historyMessages.last?.message.messageId {
            return lastMessageId == message.messageId
        }
        return false
    }
    
    private func presentAlertController(title: String) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: Strings.Localizable.ok, style: .cancel)
        alertController.addAction(cancel)
        chatViewController?.present(viewController: alertController)
    }
}

extension ChatRoomDelegate: MEGATransferDelegate {
    // MARK: - MEGATransferDelegate methods
    
    nonisolated func onTransferStart(_: MEGASdk, transfer: MEGATransfer) {
        Task { @MainActor in
            handleOnTransferStart(transfer)
        }
    }
    
    nonisolated func onTransferFinish(_: MEGASdk, transfer: MEGATransfer, error _: MEGAError) {
        Task { @MainActor in
            handleOnTransferFinish(transfer)
        }
    }
    
    nonisolated func onTransferUpdate(_: MEGASdk, transfer: MEGATransfer) {
        Task { @MainActor in
            handleOnTransferUpdate(transfer)
        }
    }
    
    private func handleOnTransferStart(_ transfer: MEGATransfer) {
        guard let appData = transfer.appData else {
            return
        }
        if appData.contains("\(chatRoom.chatId)"), transfer.type == .upload {
            insertTransfer(transfer)
            chatViewController?.checkTransferPauseStatus()
        } else if appData.contains("downloadAttachToMessageID") {
            let messageID = transfer.mnz_extractMessageIDFromAppData()
            
            chatMessages = chatMessages.map({ (chatMessage) -> any MessageType in
                
                if var chatMessage = chatMessage as? ChatMessage, chatMessage.messageId ==  messageID {
                    chatMessage.transfer = transfer
                    return chatMessage
                }
                
                return chatMessage
            })
            
            chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
            if isLastSectionVisible() {
                chatViewController?.scrollToBottom(animated: false)
            }
        }
    }
    
    private func handleOnTransferFinish(_ transfer: MEGATransfer) {
        guard let appData = transfer.appData else {
            return
        }
        if appData.contains("\(chatRoom.chatId)") {
            transfers = transfers.map { (chatMessage) -> ChatMessage in
                
                if chatMessage.transfer?.tag == transfer.tag {
                    return ChatMessage(transfer: transfer, chatRoom: chatRoom)
                }
                
                return chatMessage
            }
        } else if appData.contains("downloadAttachToMessageID") {
            let messageID = transfer.mnz_extractMessageIDFromAppData()
            
            chatMessages = chatMessages.map({ (chatMessage) -> any MessageType in
                
                if var chatMessage = chatMessage as? ChatMessage, chatMessage.messageId ==  messageID {
                    chatMessage.transfer = transfer
                    return chatMessage
                }
                
                return chatMessage
            })
            
            chatViewController?.messagesCollectionView.reloadDataAndKeepOffset()
            if isLastSectionVisible() {
                chatViewController?.scrollToBottom(animated: false)
            }
        }
    }
    
    private func handleOnTransferUpdate(_ transfer: MEGATransfer) {
        guard let appData = transfer.appData else {
            return
        }
        if appData.contains("\(chatRoom.chatId)") {
            transfers = transfers.map { (chatMessage) -> ChatMessage in
                
                if chatMessage.transfer?.tag == transfer.tag {
                    return ChatMessage(transfer: transfer, chatRoom: chatRoom)
                }
                
                return chatMessage
            }
        }
    }
}
