import Foundation

public struct CancellableTransferEntity: Sendable {
    public let handle: HandleEntity
    public let parentHandle: HandleEntity
    public let messageId: HandleEntity
    public let chatId: HandleEntity
    public let fileLinkURL: URL?
    public let localFileURL: URL?
    public let appData: String?
    public let startFirst: Bool
    public let isFile: Bool
    public let type: CancellableTransferTypeEntity
    public let uploadOptions: UploadOptionsEntity?
    public let name: String?

    public init(
        handle: HandleEntity = .invalid,
        parentHandle: HandleEntity = .invalid,
        messageId: HandleEntity = .invalid,
        chatId: HandleEntity = .invalid,
        fileLinkURL: URL? = nil,
        localFileURL: URL? = nil,
        appData: String? = nil,
        startFirst: Bool = false,
        isFile: Bool = true,
        type: CancellableTransferTypeEntity,
        uploadOptions: UploadOptionsEntity? = nil,
        name: String? = nil
    ) {
        self.handle = handle
        self.parentHandle = parentHandle
        self.messageId = messageId
        self.chatId = chatId
        self.fileLinkURL = fileLinkURL
        self.localFileURL = localFileURL
        self.name = name
        self.appData = appData
        self.startFirst = startFirst
        self.isFile = isFile
        self.type = type
        self.uploadOptions = uploadOptions
    }
}

public enum CancellableTransferTypeEntity: Sendable {
    case download
    case upload
    case downloadChat
    case downloadFileLink
}
