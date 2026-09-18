import Foundation
import MEGAPreference
import MEGASwift

public protocol DownloadNodeUseCaseProtocol: Sendable {
    func downloadFileToOffline(
        forNodeHandle handle: HandleEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity>
    
    /// Downloads an already resolved node to Offline.
    ///
    /// For the sources whose nodes cannot be looked up again: a public album link's photos come from a set
    /// preview and are in neither the account tree nor the folder link SDK, so the entity the caller
    /// already holds is the only handle on them there is.
    func downloadFileToOffline(
        _ node: NodeEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity>

    func downloadChatFileToOffline(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity>
    
    func downloadFileToTempFolder(node: NodeEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity>
    
    func downloadFileLinkToOffline(
        _ fileLink: FileLinkEntity,
        filename: String?,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity>
    
    func cancelDownloadTransfers()
}

public struct DownloadNodeUseCase<T: DownloadFileRepositoryProtocol, V: FileSystemRepositoryProtocol, W: NodeRepositoryProtocol, Y: NodeDataRepositoryProtocol, Z: FileCacheRepositoryProtocol, M: MediaUseCaseProtocol, P: PreferenceRepositoryProtocol, H: ChatNodeRepositoryProtocol, I: DownloadChatRepositoryProtocol>: DownloadNodeUseCaseProtocol {
    private let downloadFileRepository: T
    private let fileSystemRepository: V
    private let nodeRepository: W
    private let nodeDataRepository: Y
    private let fileCacheRepository: Z
    private let mediaUseCase: M
    private let preferenceRepository: P
    private let chatNodeRepository: H
    private let downloadChatRepository: I
    
    @PreferenceWrapper(key: PreferenceKeyEntity.savePhotoToGallery, defaultValue: false)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.saveVideoToGallery, defaultValue: false)
    private var saveVideoInGallery: Bool
    
    public init(downloadFileRepository: T, fileSystemRepository: V, nodeRepository: W, nodeDataRepository: Y, fileCacheRepository: Z, mediaUseCase: M, preferenceRepository: P, chatNodeRepository: H, downloadChatRepository: I) {
        self.downloadFileRepository = downloadFileRepository
        self.fileSystemRepository = fileSystemRepository
        self.nodeRepository = nodeRepository
        self.nodeDataRepository = nodeDataRepository
        self.fileCacheRepository = fileCacheRepository
        self.mediaUseCase = mediaUseCase
        self.preferenceRepository = preferenceRepository
        self.chatNodeRepository = chatNodeRepository
        self.downloadChatRepository = downloadChatRepository
        $savePhotoInGallery.useCase = PreferenceUseCase(repository: preferenceRepository)
        $saveVideoInGallery.useCase = PreferenceUseCase(repository: preferenceRepository)
    }
    
    public func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appData: String?, startFirst: Bool) throws -> AnyAsyncSequence<TransferEventEntity> {
        guard let node = nodeRepository.nodeForHandle(handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        
        return try downloadFileToOffline(node, filename: filename, appData: appData, startFirst: startFirst)
    }
    
    public func downloadFileToOffline(_ node: NodeEntity, filename: String?, appData: String?, startFirst: Bool) throws -> AnyAsyncSequence<TransferEventEntity> {
        if !shouldDownloadToGallery(name: node.name), !node.isFile {
            guard node.name != "Inbox" else {
                throw TransferErrorEntity.inboxFolderNameNotAllowed
            }
        }

        return try downloadFileRepository.downloadFile(
            forNodeHandle: node.handle,
            to: fileSystemRepository.documentsDirectory(),
            filename: filename,
            appdata: appData,
            startFirst: startFirst
        )
    }
    
    @MainActor
    public func downloadChatFileToOffline(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity> {
        
        guard await chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) != nil else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }

        return try downloadChatRepository.downloadChatFile(
            forNodeHandle: handle,
            messageId: messageId,
            chatId: chatId,
            to: fileSystemRepository.documentsDirectory(),
            filename: filename,
            appdata: appdata,
            startFirst: startFirst
        )
    }

    public func downloadFileToTempFolder(node: NodeEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        guard BatchDownloadFeatureFlag.isEnabled else {
            return try downloadFileRepository.downloadTo(fileCacheRepository.tempFolder, nodeHandle: node.handle, appData: appData)
        }

        return downloadFileToTempFolderInBatch(node: node, appData: appData)
    }
    
    private func downloadFileToTempFolderInBatch(node: NodeEntity, appData: String?) -> AnyAsyncSequence<TransferEventEntity> {
        let item = DownloadBatchItemEntity(
            source: .node(node.handle),
            destination: .folder(fileCacheRepository.base64HandleTempFolder(for: node.base64Handle)),
            appData: appData,
            startFirst: true
        )

        return downloadFileRepository.downloadBatchFileItemProgress(item: item).eraseToAnyAsyncSequence()
    }

    public func downloadFileLinkToOffline(
        _ fileLink: FileLinkEntity,
        filename: String?,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity> {
        let node = try await nodeRepository.nodeFor(fileLink: fileLink)
        
        return try downloadFileRepository.downloadFileLink(
            fileLink,
            named: node.name,
            to: fileSystemRepository.documentsDirectory(),
            metaData: metaData,
            startFirst: true
        )
    }
    
    public func cancelDownloadTransfers() {
        downloadFileRepository.cancelDownloadTransfers()
    }

    // MARK: - Private
    private func shouldDownloadToGallery(name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        return mediaUseCase.isImage(name) && savePhotoInGallery || mediaUseCase.isVideo(name) && saveVideoInGallery
    }
}
