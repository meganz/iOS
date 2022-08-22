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
}
