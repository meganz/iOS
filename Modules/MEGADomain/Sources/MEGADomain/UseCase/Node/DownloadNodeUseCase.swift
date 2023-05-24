import Foundation

public protocol DownloadNodeUseCaseProtocol {
    func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?, folderUpdate: ((FolderTransferUpdateEntity) -> Void)?)
    func downloadChatFileToOffline(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, metaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func cancelDownloadTransfers()
}

public struct DownloadNodeUseCase<T: DownloadFileRepositoryProtocol, U: OfflineFilesRepositoryProtocol, V: FileSystemRepositoryProtocol, W: NodeRepositoryProtocol, Y: NodeDataRepositoryProtocol, Z: FileCacheRepositoryProtocol, M: MediaUseCaseProtocol, P: PreferenceRepositoryProtocol, G: OfflineFileFetcherRepositoryProtocol>: DownloadNodeUseCaseProtocol {
    private let downloadFileRepository: T
    private let offlineFilesRepository: U
    private let fileSystemRepository: V
    private let nodeRepository: W
    private let nodeDataRepository: Y
    private let fileCacheRepository: Z
    private let mediaUseCase: M
    private let preferenceRepository: P
    private let offlineFileFetcherRepository: G
    
    @PreferenceWrapper(key: .savePhotoToGallery, defaultValue: false)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: .saveVideoToGallery, defaultValue: false)
    private var saveVideoInGallery: Bool
    
    public init(downloadFileRepository: T, offlineFilesRepository: U, fileSystemRepository: V, nodeRepository: W, nodeDataRepository: Y, fileCacheRepository: Z, mediaUseCase: M, preferenceRepository: P, offlineFileFetcherRepository: G) {
        self.downloadFileRepository = downloadFileRepository
        self.offlineFilesRepository = offlineFilesRepository
        self.fileSystemRepository = fileSystemRepository
        self.nodeRepository = nodeRepository
        self.nodeDataRepository = nodeDataRepository
        self.fileCacheRepository = fileCacheRepository
        self.mediaUseCase = mediaUseCase
        self.preferenceRepository = preferenceRepository
        self.offlineFileFetcherRepository = offlineFileFetcherRepository
        $savePhotoInGallery.useCase = PreferenceUseCase(repository: preferenceRepository)
        $saveVideoInGallery.useCase = PreferenceUseCase(repository: preferenceRepository)
    }
    
    public func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?, folderUpdate: ((FolderTransferUpdateEntity) -> Void)?) {
        guard let node = nodeRepository.nodeForHandle(handle) else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        if !shouldDownloadToGallery(name: node.name) {
            if node.isFile {
                guard offlineFileFetcherRepository.offlineFile(for: node.base64Handle) == nil else {
                    completion?(.failure(.alreadyDownloaded))
                    return
                }
                
                let tempUrl = tempURL(for: node)
                if fileSystemRepository.fileExists(at: tempUrl) {
                    let offlineUrl = fileCacheRepository.offlineFileURL(name: node.name)
                    if fileSystemRepository.copyFile(at: tempUrl, to: offlineUrl, name: node.name) {
                        offlineFilesRepository.createOfflineFile(name: node.name, for: handle)
                        completion?(.failure(.copiedFromTempFolder))
                        return
                    }
                }
            } else {
                guard node.name != "Inbox" else {
                    completion?(.failure(.inboxFolderNameNotAllowed))
                    return
                }
            }
        }
        
        guard let nodeSize = nodeDataRepository.sizeForNode(handle: handle), fileSystemRepository.systemVolumeAvailability() > nodeSize else {
            completion?(.failure(.notEnoughSpace))
            return
        }

        downloadFileRepository.downloadFile(forNodeHandle: handle, to: fileSystemRepository.documentsDirectory(), filename: filename, appdata: appdata, startFirst: startFirst, start: start, update: update, folderUpdate: folderUpdate) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    public func downloadChatFileToOffline(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        guard let node = nodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
                
        if !shouldDownloadToGallery(name: node.name) {
            guard offlineFileFetcherRepository.offlineFile(for: node.base64Handle) == nil else {
                completion?(.failure(.alreadyDownloaded))
                return
            }
            
            let tempUrl = tempURL(for: node)
            if fileSystemRepository.fileExists(at: tempUrl) {
                let offlineUrl = fileCacheRepository.offlineFileURL(name: node.name)
                if fileSystemRepository.copyFile(at: tempUrl, to: offlineUrl, name: node.name) {
                    offlineFilesRepository.createOfflineFile(name: node.name, for: handle)
                    completion?(.failure(.copiedFromTempFolder))
                    return
                }
            }
        }
        
        guard let nodeSize = nodeDataRepository.sizeForChatNode(handle: handle, messageId: messageId, chatId: chatId), fileSystemRepository.systemVolumeAvailability() > nodeSize else {
            completion?(.failure(.notEnoughSpace))
            return
        }

        downloadFileRepository.downloadChatFile(forNodeHandle: handle, messageId: messageId, chatId: chatId, to: fileSystemRepository.documentsDirectory(), filename: filename, appdata: appdata, startFirst: startFirst, start: start, update: update) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    public func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        downloadFileRepository.downloadTo(fileCacheRepository.tempFolder, nodeHandle: nodeHandle, appData: appData, progress: update, completion: completion)
    }
    
    public func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, metaData: TransferMetaDataEntity?, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        nodeRepository.nodeFor(fileLink: fileLink) { result in
            switch result {
            case .success(let node):
                guard fileSystemRepository.systemVolumeAvailability() > node.size else {
                    completion(.failure(.notEnoughSpace))
                    return
                }
                downloadFileRepository.downloadFileLink(fileLink, named: node.name, to: fileSystemRepository.documentsDirectory(), metaData: metaData, startFirst: true, start: start, update: update, completion: completion)
            case .failure:
                completion(.failure(.couldNotFindNodeByLink))
            }
        }
    }
    
    public func cancelDownloadTransfers() {
        downloadFileRepository.cancelDownloadTransfers()
    }

    //MARK: - Private
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
