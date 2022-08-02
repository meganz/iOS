
@objc final class CancellableTransfer: NSObject {
    let handle: HandleEntity
    let parentHandle: HandleEntity
    let messageId: HandleEntity
    let chatId: HandleEntity
    let fileLinkURL: URL?
    let path: String
    var name: String?
    let appData: String?
    let priority: Bool
    let isFile: Bool
    let type: CancellableTransferType
    var state: TransferStateEntity = .none
    var stage: TransferStageEntity = .none
    
    @objc init(handle: HandleEntity = .invalid, parentHandle: HandleEntity = .invalid, fileLinkURL: URL? = nil, path: String, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = parentHandle
        self.messageId = .invalid
        self.chatId = .invalid
        self.fileLinkURL = fileLinkURL
        self.path = path
        self.name = name
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
    }
    
    @objc init(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, fileLinkURL: URL? = nil, path: String, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = .invalid
        self.messageId = messageId
        self.chatId = chatId
        self.fileLinkURL = fileLinkURL
        self.path = path
        self.name = name
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
    }
}
