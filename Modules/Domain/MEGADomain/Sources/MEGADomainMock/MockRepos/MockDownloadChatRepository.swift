import Foundation
import MEGADomain
import MEGASwift

final public class MockDownloadChatRepository: DownloadChatRepositoryProtocol, @unchecked Sendable {
    /// One `downloadChatFile(...)` call, kept so a test can tell the legacy chat download apart from
    /// the batch one.
    public struct DownloadChatFileCall: Equatable, Sendable {
        public let handle: HandleEntity
        public let messageId: HandleEntity
        public let chatId: HandleEntity
        public let url: URL
        public let filename: String?
        public let appdata: String?
        public let startFirst: Bool

        public init(
            handle: HandleEntity,
            messageId: HandleEntity,
            chatId: HandleEntity,
            url: URL,
            filename: String?,
            appdata: String?,
            startFirst: Bool
        ) {
            self.handle = handle
            self.messageId = messageId
            self.chatId = chatId
            self.url = url
            self.filename = filename
            self.appdata = appdata
            self.startFirst = startFirst
        }
    }

    /// Every `downloadChatFile(...)` call, in call order.
    @Atomic public var downloadChatFileCalls = [DownloadChatFileCall]()

    private let downloadChatFileError: (any Error)?

    public static var newRepo: MockDownloadChatRepository {
        MockDownloadChatRepository()
    }
    
    public init(downloadChatFileError: (any Error)? = nil) {
        self.downloadChatFileError = downloadChatFileError
    }
    
    public func downloadChat(
        nodeHandle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> TransferEntity {
        TransferEntity()
    }
    
    public func downloadChatFile(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        $downloadChatFileCalls.mutate {
            $0.append(
                DownloadChatFileCall(
                    handle: handle,
                    messageId: messageId,
                    chatId: chatId,
                    url: url,
                    filename: filename,
                    appdata: appdata,
                    startFirst: startFirst
                )
            )
        }
        if let downloadChatFileError {
            throw downloadChatFileError
        }
        return EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
