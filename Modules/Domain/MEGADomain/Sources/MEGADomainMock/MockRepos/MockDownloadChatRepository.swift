import Foundation
import MEGADomain
import MEGASwift

final public class MockDownloadChatRepository: DownloadChatRepositoryProtocol {
    public static var newRepo: MockDownloadChatRepository {
        MockDownloadChatRepository()
    }
    
    public init() {}
    
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
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
