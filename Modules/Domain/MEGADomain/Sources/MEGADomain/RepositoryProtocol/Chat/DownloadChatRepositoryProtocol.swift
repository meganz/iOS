import Foundation

public protocol DownloadChatRepositoryProtocol: RepositoryProtocol {
    func downloadChat(
        nodeHandle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void
    )
    
    func downloadChatFile(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to url: URL,
        filename: String?,
        appdata: String?,
        startFirst: Bool,
        start: ((TransferEntity) -> Void)?,
        update: ((TransferEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    )
}
