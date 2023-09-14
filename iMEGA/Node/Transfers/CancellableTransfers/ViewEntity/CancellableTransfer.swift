import MEGADomain

@objc final class CancellableTransfer: NSObject {
    let handle: HandleEntity
    let parentHandle: HandleEntity
    let messageId: HandleEntity
    let chatId: HandleEntity
    let fileLinkURL: URL?
    let localFileURL: URL?
    var name: String?
    let appData: String?
    let priority: Bool
    let isFile: Bool
    let type: CancellableTransferType
    var state: TransferStateEntity = .none
    var stage: TransferStageEntity = .none
    
    @objc init(handle: HandleEntity = .invalid, parentHandle: HandleEntity = .invalid, fileLinkURL: URL? = nil, localFileURL: URL? = nil, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = parentHandle
        self.messageId = .invalid
        self.chatId = .invalid
        self.fileLinkURL = fileLinkURL
        self.localFileURL = localFileURL
        self.name = name
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
    }
    
    @objc init(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, fileLinkURL: URL? = nil, localFileURL: URL? = nil, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = .invalid
        self.messageId = messageId
        self.chatId = chatId
        self.fileLinkURL = fileLinkURL
        self.localFileURL = localFileURL
        self.name = name
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
    }
    
    struct Factory {
        let node: MEGANode
        let isNodeFromFolderLink: Bool
        let messageId: HandleEntity?
        let chatId: HandleEntity?
        
        func make() -> CancellableTransfer {
            let type: () -> CancellableTransferType = {
                if let messageId = messageId, let chatId = chatId, messageId != .invalid || chatId != .invalid {
                    return .downloadChat
                } else {
                    return .download
                }
            }
            
            let messageIdIfValid: (_ messageId: HandleEntity?) -> HandleEntity = { messageId in
                if let messageId, messageId != .invalid {
                    return messageId
                }
                return .invalid
            }
            
            let chatIdIfValid: (_ chatId: HandleEntity?) -> HandleEntity = { chatId in
                if let chatId, chatId != .invalid {
                    return chatId
                }
                return .invalid
            }
            
            return .init(
                handle: node.handle,
                messageId: messageIdIfValid(messageId),
                chatId: chatIdIfValid(chatId),
                name: nil,
                appData: nil,
                priority: false,
                isFile: node.isFile(),
                type: type()
            )
        }
    }
}
