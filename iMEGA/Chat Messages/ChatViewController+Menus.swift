import ChatRepo
import Foundation
import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension ChatViewController {
    
    func copyMessage(_ message: ChatMessage) {
        let megaMessage = message.message
        if megaMessage.type == .normal || megaMessage.type == .containsMeta {
            if let content = megaMessage.content {
                UIPasteboard.general.string = content
            }
        } else if megaMessage.type == .attachment {
            if megaMessage.nodeList?.size == 1,
               let node = megaMessage.nodeList?.node(at: 0),
               let name = node.name,
               name.fileExtensionGroup.isImage {
                let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
                let originalImagePath = Helper.pathWithOriginalName(for: node, inSharedSandboxCacheDirectory: "originalV3")
                if FileManager.default.fileExists(atPath: originalImagePath), let originalImage = UIImage(contentsOfFile: originalImagePath) {
                    UIPasteboard.general.image = originalImage
                } else if FileManager.default.fileExists(atPath: previewFilePath), let previewImage = UIImage(contentsOfFile: previewFilePath) {
                    UIPasteboard.general.image = previewImage
                }
            }
        }
    }
    
    func forwardMessage(_ message: ChatMessage) {
        selectedMessages = [message]
        forwardSelectedMessages()
    }
    
    func editMessage(_ message: ChatMessage) {
        editMessage = message
        if message.message.containsMeta?.type == MEGAChatContainsMetaType.geolocation {
            self.presentShareLocation(editing: true)
        } else {
            guard let content = editMessage?.message.content else {
                return
            }
            chatInputBar?.set(text: content)
        }
    }
    
    func deleteMessage(_ chatMessage: ChatMessage) {
        
        let megaMessage =  chatMessage.message
        
        if megaMessage.type == .attachment ||
            megaMessage.type == .voiceClip {
            if audioController.playingMessage?.messageId == chatMessage.messageId {
                if audioController.state == .playing {
                    audioController.stopAnyOngoingPlaying()
                }
            }
            MEGAChatSdk.shared.revokeAttachmentMessage(forChat: chatRoom.chatId, messageId: megaMessage.messageId)
        } else {
            let foundIndex = messages.firstIndex { message -> Bool in
                guard let localChatMessage = message as? ChatMessage else {
                    return false
                }
                
                return chatMessage == localChatMessage
            }
            
            guard let index = foundIndex else {
                return
            }
            
            if megaMessage.status == .sending {
                chatRoomDelegate.chatMessages.remove(at: index)
                messagesCollectionView.performBatchUpdates({
                    messagesCollectionView.deleteSections([index])
                }, completion: nil)
            } else {
                let messageId = megaMessage.status == .sending ? megaMessage.temporalId : megaMessage.messageId
                let deleteMessage = MEGAChatSdk.shared.deleteMessage(forChat: chatRoom.chatId, messageId: messageId)
                deleteMessage?.chatId = chatRoom.chatId
                chatRoomDelegate.chatMessages[index] = ChatMessage(message: deleteMessage!, chatRoom: chatRoom)
            }
        }
        
    }
    
    func removeRichPreview(_ message: ChatMessage) {
        let megaMessage =  message.message
        MEGAChatSdk.shared.removeRichLink(forChat: chatRoom.chatId, messageId: megaMessage.messageId)
    }
    
    func downloadMessage(_ messages: [ChatMessage]) {
        var transfers = [CancellableTransfer]()
        for message in messages {
            guard let nodelist = message.message.nodeList else { return }

            for index in 0..<nodelist.size {
                var node = nodelist.node(at: index)
                if chatRoom.isPreview {
                    if let nodeAt = nodelist.node(at: index) {
                        node = sdk.authorizeNode(nodeAt)
                    }
                }
                if let node = node {
                    transfers.append(CancellableTransfer(handle: node.handle, messageId: message.message.messageId, chatId: chatRoom.chatId, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .downloadChat))
                }
            }
        }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .downloadChat).start()
    }
    
    func importMessage(_ messages: [ChatMessage]) {

        var nodes = [MEGANode]()
        
        for message in messages {
            let megaMessage = message.message
            
            guard let nodelist = megaMessage.nodeList else { return }
            
            for index in 0..<nodelist.size {
                var node = nodelist.node(at: index)
                if chatRoom.isPreview {
                    if let nodeAt = nodelist.node(at: index) {
                        node = sdk.authorizeNode(nodeAt)
                    }
                }
                if let node = node {
                    nodes.append(node)
                }
            }
        }
        
        let navigationController = UIStoryboard.init(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
        
        let browserVC = navigationController.viewControllers.first as! BrowserViewController
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = .import
        
        present(viewController: navigationController)
        
    }
    
    func addContactMessage(_ message: ChatMessage) {
        let megaMessage =  message.message

        let usersCount = megaMessage.usersCount
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate(numberOfRequests: usersCount)
        for index in 0..<usersCount {
            if let email = megaMessage.userEmail(at: index) {
                sdk.inviteContact(withEmail: email, message: "", action: .add, delegate: inviteContactRequestDelegate)
            }
        }
        
    }
    
    func saveToPhotos(_ messages: [ChatMessage]) {
        for chatMessage in messages {
            guard let nodelist = chatMessage.message.nodeList else { continue }
            if nodelist.size == 1,
               let node = nodelist.node(at: 0),
               node.name?.fileExtensionGroup.isVisualMedia == true {
                if chatRoom.isPreview,
                   let authorizationToken = chatRoom.authorizationToken,
                   let authorizedNode = sdk.authorizeChatNode(node, cauth: authorizationToken) {
                    saveToPhotos(node: authorizedNode, chatMessage: chatMessage, chatRoom: chatRoom)
                } else {
                    saveToPhotos(node: node, chatMessage: chatMessage, chatRoom: chatRoom)
                }
            } else {
                MEGALogDebug("Wrong Message type to be saved to album")
            }
        }
    }
    
    private func saveToPhotos(node: MEGANode, chatMessage: ChatMessage, chatRoom: ChatRoomEntity) {
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: .shared), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo, chatNodeRepository: ChatNodeRepository.newRepo, downloadChatRepository: DownloadChatRepository.newRepo)
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
        
        Task(priority: .userInitiated) {
            do {
                try await saveMediaUseCase.saveToPhotosChatNode(handle: node.handle, messageId: chatMessage.message.messageId, chatId: chatRoom.chatId)
            } catch let error as SaveMediaToPhotosErrorEntity {
                if error != .cancelled {
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(UIImage(resource: .saveToPhotos), status: Strings.Localizable.somethingWentWrong)
                }
            }
        }
    }
    
    func select(_ message: ChatMessage) {
        selectedMessages.insert(message)
        customToolbar(type: .text)
        setEditing(true, animated: true)
        
        guard let index = messages.firstIndex(where: { chatMessage -> Bool in
            guard let chatMessage = chatMessage as? ChatMessage else {
                return false
            }
            return message == chatMessage
        }) else { return }
        
        messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .centeredVertically, animated: true)
    }
}
