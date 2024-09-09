import MEGADomain
import MEGASwift

@objc final class CancellableTransfer: NSObject, @unchecked Sendable {
    let handle: HandleEntity
    let parentHandle: HandleEntity
    let messageId: HandleEntity
    let chatId: HandleEntity
    let fileLinkURL: URL?
    let localFileURL: URL?
    let appData: String?
    let priority: Bool
    let isFile: Bool
    let type: CancellableTransferType
    @Atomic var name: String?
    @Atomic var state: TransferStateEntity = .none
    @Atomic var stage: TransferStageEntity = .none
    
    @objc init(handle: HandleEntity = .invalid, parentHandle: HandleEntity = .invalid, fileLinkURL: URL? = nil, localFileURL: URL? = nil, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = parentHandle
        self.messageId = .invalid
        self.chatId = .invalid
        self.fileLinkURL = fileLinkURL
        self.localFileURL = localFileURL
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
        super.init()
        self.$name.mutate { $0 = name }
    }
    
    @objc init(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, fileLinkURL: URL? = nil, localFileURL: URL? = nil, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = .invalid
        self.messageId = messageId
        self.chatId = chatId
        self.fileLinkURL = fileLinkURL
        self.localFileURL = localFileURL
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
        super.init()
        self.$name.mutate { $0 = name }
    }
    
    public func setState(_ newState: TransferStateEntity) {
        $state.mutate { $0 = newState }
    }
    
    public func setStage(_ newStage: TransferStageEntity) {
        $stage.mutate { $0 = newStage }
    }
    
    public func setName(_ newName: String?) {
        $name.mutate { $0 = newName }
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
