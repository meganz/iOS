import Foundation
import MEGASwift

public protocol DownloadNodeUseCaseProtocol: Sendable {
    func downloadFileToOffline(
        forNodeHandle handle: HandleEntity,
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
    
    func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity>
    
    func downloadFileLinkToOffline(
        _ fileLink: FileLinkEntity,
        filename: String?,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity>
    
    func cancelDownloadTransfers()
}

public struct DownloadNodeUseCase<T: DownloadFileRepositoryProtocol, U: OfflineFilesRepositoryProtocol, V: FileSystemRepositoryProtocol, W: NodeRepositoryProtocol, Y: NodeDataRepositoryProtocol, Z: FileCacheRepositoryProtocol, M: MediaUseCaseProtocol, P: PreferenceRepositoryProtocol, G: OfflineFileFetcherRepositoryProtocol, H: ChatNodeRepositoryProtocol, I: DownloadChatRepositoryProtocol>: DownloadNodeUseCaseProtocol {
    private let downloadFileRepository: T
    private let offlineFilesRepository: U
    private let fileSystemRepository: V
    private let nodeRepository: W
    private let nodeDataRepository: Y
    private let fileCacheRepository: Z
    private let mediaUseCase: M
    private let preferenceRepository: P
    private let offlineFileFetcherRepository: G
    private let chatNodeRepository: H
    private let downloadChatRepository: I
    
    @PreferenceWrapper(key: .savePhotoToGallery, defaultValue: false)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: .saveVideoToGallery, defaultValue: false)
    private var saveVideoInGallery: Bool
    
    public init(downloadFileRepository: T, offlineFilesRepository: U, fileSystemRepository: V, nodeRepository: W, nodeDataRepository: Y, fileCacheRepository: Z, mediaUseCase: M, preferenceRepository: P, offlineFileFetcherRepository: G, chatNodeRepository: H, downloadChatRepository: I) {
        self.downloadFileRepository = downloadFileRepository
        self.offlineFilesRepository = offlineFilesRepository
        self.fileSystemRepository = fileSystemRepository
        self.nodeRepository = nodeRepository
        self.nodeDataRepository = nodeDataRepository
        self.fileCacheRepository = fileCacheRepository
        self.mediaUseCase = mediaUseCase
        self.preferenceRepository = preferenceRepository
        self.offlineFileFetcherRepository = offlineFileFetcherRepository
        self.chatNodeRepository = chatNodeRepository
        self.downloadChatRepository = downloadChatRepository
        $savePhotoInGallery.useCase = PreferenceUseCase(repository: preferenceRepository)
        $saveVideoInGallery.useCase = PreferenceUseCase(repository: preferenceRepository)
    }
    
    public func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appData: String?, startFirst: Bool) throws -> AnyAsyncSequence<TransferEventEntity> {

        guard let node = nodeRepository.nodeForHandle(handle) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
        
        if !shouldDownloadToGallery(name: node.name) {
            if node.isFile {
                guard offlineFileFetcherRepository.offlineFile(for: node.base64Handle) == nil else {
                    throw TransferErrorEntity.alreadyDownloaded
                }
                
                let tempUrl = tempURL(for: node)
                if fileSystemRepository.fileExists(at: tempUrl) {
                    let offlineUrl = fileCacheRepository.offlineFileURL(name: node.name)
                    if fileSystemRepository.copyFile(at: tempUrl, to: offlineUrl) {
                        offlineFilesRepository.createOfflineFile(name: node.name, for: handle)
                        throw TransferErrorEntity.copiedFromTempFolder
                    }
                }
            } else {
                guard node.name != "Inbox" else {
                    throw TransferErrorEntity.inboxFolderNameNotAllowed
                }
            }
        }

        return try downloadFileRepository.downloadFile(
            forNodeHandle: handle,
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
        
        guard let node = await chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            throw TransferErrorEntity.couldNotFindNodeByHandle
        }
                
        if !shouldDownloadToGallery(name: node.name) {
            guard offlineFileFetcherRepository.offlineFile(for: node.base64Handle) == nil else {
                throw TransferErrorEntity.alreadyDownloaded
            }
            
            let tempUrl = tempURL(for: node)
            if fileSystemRepository.fileExists(at: tempUrl) {
                let offlineUrl = fileCacheRepository.offlineFileURL(name: node.name)
                if fileSystemRepository.copyFile(at: tempUrl, to: offlineUrl) {
                    offlineFilesRepository.createOfflineFile(name: node.name, for: handle)
                    throw TransferErrorEntity.copiedFromTempFolder
                }
            }
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

    public func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        try downloadFileRepository.downloadTo(fileCacheRepository.tempFolder, nodeHandle: nodeHandle, appData: appData)
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
    private func tempURL(for node: NodeEntity) -> URL {
        mediaUseCase.isImage(node.name) ? fileCacheRepository.cachedOriginalURL(for: node.base64Handle, name: node.name) : fileCacheRepository.tempFileURL(for: node)
    }
    
    private func shouldDownloadToGallery(name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        return mediaUseCase.isImage(name) && savePhotoInGallery || mediaUseCase.isVideo(name) && saveVideoInGallery
    }
}
