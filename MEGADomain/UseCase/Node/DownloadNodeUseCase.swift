import MEGADomain

protocol DownloadNodeUseCaseProtocol {
    func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadChatFileToOffline(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?, cancelToken: MEGACancelToken?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
    func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, transferMetaData: TransferMetaDataEntity?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
}

struct DownloadNodeUseCase<T: DownloadFileRepositoryProtocol, U: OfflineFilesRepositoryProtocol, V: FileSystemRepositoryProtocol, W: NodeRepositoryProtocol, Z: FileCacheRepositoryProtocol>: DownloadNodeUseCaseProtocol {
    private let downloadFileRepository: T
    private let offlineFilesRepository: U
    private let fileSystemRepository: V
    private let nodeRepository: W
    private let fileCacheRepository: Z
    
    @PreferenceWrapper(key: .savePhotoToGallery, defaultValue: false, useCase: PreferenceUseCase.default)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: .saveVideoToGallery, defaultValue: false, useCase: PreferenceUseCase.default)
    private var saveVideoInGallery: Bool
    
    init(downloadFileRepository: T, offlineFilesRepository: U, fileSystemRepository: V, nodeRepository: W, fileCacheRepository: Z) {
        self.downloadFileRepository = downloadFileRepository
        self.offlineFilesRepository = offlineFilesRepository
        self.fileSystemRepository = fileSystemRepository
        self.nodeRepository = nodeRepository
        self.fileCacheRepository = fileCacheRepository
    }
    
    func downloadFileToOffline(forNodeHandle handle: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        guard let node = nodeRepository.nodeForHandle(handle) else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
        
        if !shouldDownloadToGallery(name: node.name) {
            if node.isFile {
                guard offlineFilesRepository.offlineFile(for: node.base64Handle) == nil else {
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
                guard (node.name != "Inbox") else {
                    completion?(.failure(.inboxFolderNameNotAllowed))
                    return
                }
            }
        }
        
        guard let nodeSize = nodeRepository.sizeForNode(handle: handle), fileSystemRepository.systemVolumeAvailability() > nodeSize else {
            completion?(.failure(.notEnoughSpace))
            return
        }

        downloadFileRepository.downloadFile(forNodeHandle: handle, to: fileSystemRepository.documentsDirectory(), filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken, start: start, update: update) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    func downloadChatFileToOffline(forNodeHandle handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        guard let node = nodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            completion?(.failure(.couldNotFindNodeByHandle))
            return
        }
                
        if !shouldDownloadToGallery(name: node.name) {
            guard offlineFilesRepository.offlineFile(for: node.base64Handle) == nil else {
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
        
        guard let nodeSize = nodeRepository.sizeForChatNode(handle: handle, messageId: messageId, chatId: chatId), fileSystemRepository.systemVolumeAvailability() > nodeSize else {
            completion?(.failure(.notEnoughSpace))
            return
        }

        downloadFileRepository.downloadChatFile(forNodeHandle: handle, messageId: messageId, chatId: chatId, to: fileSystemRepository.documentsDirectory(), filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken, start: start, update: update) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?, cancelToken: MEGACancelToken?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        downloadFileRepository.downloadTo(fileCacheRepository.tempFolder, nodeHandle: nodeHandle, appData: appData, cancelToken: cancelToken, progress: update, completion: completion)
    }
    
    func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, transferMetaData: TransferMetaDataEntity?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        nodeRepository.nodeFor(fileLink: fileLink) { result in
            switch result {
            case .success(let node):
                guard fileSystemRepository.systemVolumeAvailability() > node.size else {
                    completion(.failure(.notEnoughSpace))
                    return
                }
                downloadFileRepository.downloadFileLink(fileLink, named: node.name, to: fileSystemRepository.documentsDirectory(), transferMetaData: transferMetaData, startFirst: true, cancelToken: nil, start: start, update: update, completion: completion)
            case .failure(_):
                completion(.failure(.couldNotFindNodeByLink))
            }
        }
    }
    
    //MARK: - Private
    private func tempURL(for node: NodeEntity) -> URL {
        node.name.mnz_isImagePathExtension ? fileCacheRepository.cachedOriginalURL(for: node.base64Handle, name: node.name) : fileCacheRepository.tempFileURL(for: node)
    }
    
    private func shouldDownloadToGallery(name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        return name.mnz_isImagePathExtension && savePhotoInGallery || name.mnz_isVideoPathExtension && saveVideoInGallery
    }
}
