
@objc final class CancellableTransfer: NSObject {
    let handle: MEGAHandle
    let parentHandle: MEGAHandle
    let messageId: MEGAHandle
    let chatId: MEGAHandle
    let path: String
    let name: String?
    let appData: String?
    let priority: Bool
    let isFile: Bool
    let type: CancellableTransferType
    var state: TransferStateEntity = .none
    var stage: TransferStageEntity = .none
    var collision: Bool = false
    
    @objc init(handle: MEGAHandle = MEGAInvalidHandle, parentHandle: MEGAHandle = .invalid, path: String, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = parentHandle
        self.messageId = .invalid
        self.chatId = .invalid
        self.path = path
        self.name = name
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
    }
    
    @objc init(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, path: String, name: String?, appData: String? = nil, priority: Bool = false, isFile: Bool = true, type: CancellableTransferType) {
        self.handle = handle
        self.parentHandle = .invalid
        self.messageId = messageId
        self.chatId = chatId
        self.path = path
        self.name = name
        self.appData = appData
        self.priority = priority
        self.isFile = isFile
        self.type = type
    }
}
