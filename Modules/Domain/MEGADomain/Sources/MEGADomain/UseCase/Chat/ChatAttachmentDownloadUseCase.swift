import Foundation

public protocol ChatAttachmentDownloadUseCaseProtocol: Sendable {
    func download(
        nodeHandle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to fileURL: URL,
        appData: String?
    ) async throws
}

public struct ChatAttachmentDownloadUseCase<
    T: DownloadFileRepositoryProtocol,
    U: DownloadChatRepositoryProtocol
>: ChatAttachmentDownloadUseCaseProtocol {
    private let downloadFileRepository: T
    private let downloadChatRepository: U

    public init(downloadFileRepository: T, downloadChatRepository: U) {
        self.downloadFileRepository = downloadFileRepository
        self.downloadChatRepository = downloadChatRepository
    }

    public func download(
        nodeHandle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        to fileURL: URL,
        appData: String?
    ) async throws {
        guard BatchDownloadFeatureFlag.isEnabled else {
            _ = try downloadChatRepository.downloadChatFile(
                forNodeHandle: nodeHandle,
                messageId: messageId,
                chatId: chatId,
                to: fileURL.deletingLastPathComponent(),
                // Named, because the repository would otherwise store the node under its own name.
                // The caller's file name is what the cache is later looked up by.
                filename: fileURL.lastPathComponent,
                appdata: appData,
                startFirst: true
            )
            return
        }

        try await downloadFileRepository.download(batch: [
            DownloadBatchItemEntity(
                source: .chatNode(handle: nodeHandle, messageId: messageId, chatId: chatId),
                destination: .file(fileURL),
                appData: appData,
                startFirst: true
            )
        ])
    }
}
