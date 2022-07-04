
protocol DownloadNodeUseCaseProtocol {
    func downloadFileToOffline(forNodeHandle handle: MEGAHandle, toPath localPath: String, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadChatFileToOffline(forNodeHandle handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, toPath localPath: String, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?)
    func downloadFileToTempFolder(nodeHandle: MEGAHandle, appData: String?, cancelToken: MEGACancelToken?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void)
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
    
    func downloadFileToOffline(forNodeHandle handle: MEGAHandle, toPath localPath: String, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        let nodeName = nodeRepository.nameForNode(handle: handle)
        
        if !shouldDownloadToGallery(name: nodeName) {
            if nodeRepository.isFileNode(handle: handle) {
                if let base64Handle = nodeRepository.base64ForNode(handle: handle) {
                    guard offlineFilesRepository.offlineFile(for: base64Handle) == nil else {
                        completion?(.failure(.alreadyDownloaded))
                        return
                    }
                    if let name = nodeName {
                        let tempUrl = tempUrlFor(base64Handle: base64Handle, name: name)
                        
                        if fileSystemRepository.fileExists(at: tempUrl) {
                            let offlineUrl = fileCacheRepository.offlineFileURL(name: name)
                            if fileSystemRepository.copyFile(at: tempUrl, to: offlineUrl, name: name) {
                                offlineFilesRepository.createOfflineFile(name: name, for: handle)
                                completion?(.failure(.copiedFromTempFolder))
                                return
                            }
                        }
                    }
                }
            } else {
                guard (nodeName != "Inbox" && localPath == offlineFilesRepository.relativeOfflinePath) else {
                    completion?(.failure(.inboxFolderNameNotAllowed))
                    return
                }
            }
        }
        
        guard let nodeSize = nodeRepository.sizeForNode(handle: handle), fileSystemRepository.systemVolumeAvailability() > nodeSize else {
            completion?(.failure(.notEnoughSpace))
            return
        }

        downloadFileRepository.downloadFile(forNodeHandle: handle, toPath: localPath, filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken, start: start, update: update) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    func downloadChatFileToOffline(forNodeHandle handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, toPath localPath: String, filename: String?, appdata: String?, startFirst: Bool, cancelToken: MEGACancelToken, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?) {
        
        let nodeName = nodeRepository.nameForChatNode(handle: handle, messageId: messageId, chatId: chatId)
        
        if !shouldDownloadToGallery(name: nodeName) {
            if let base64Handle = nodeRepository.base64ForChatNode(handle: handle, messageId: messageId, chatId: chatId)  {
                guard offlineFilesRepository.offlineFile(for: base64Handle) == nil else {
                    completion?(.failure(.alreadyDownloaded))
                    return
                }
                
                if let name = nodeName {
                    let tempUrl = tempUrlFor(base64Handle: base64Handle, name: name)
                    if fileSystemRepository.fileExists(at: tempUrl) {
                        let offlineUrl = fileCacheRepository.offlineFileURL(name: name)
                        if fileSystemRepository.copyFile(at: tempUrl, to: offlineUrl, name: name) {
                            offlineFilesRepository.createOfflineFile(name: name, for: handle)
                            completion?(.failure(.copiedFromTempFolder))
                            return
                        }
                    }
                }
            }
        }
        
        guard let nodeSize = nodeRepository.sizeForChatNode(handle: handle, messageId: messageId, chatId: chatId), fileSystemRepository.systemVolumeAvailability() > nodeSize else {
            completion?(.failure(.notEnoughSpace))
            return
        }

        downloadFileRepository.downloadChatFile(forNodeHandle: handle, messageId: messageId, chatId: chatId, toPath: localPath, filename: filename, appdata: appdata, startFirst: startFirst, cancelToken: cancelToken, start: start, update: update) { result in
            switch result {
            case .success(let transferEntity):
                completion?(.success(transferEntity))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func downloadFileToTempFolder(nodeHandle: MEGAHandle, appData: String?, cancelToken: MEGACancelToken?, update: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        downloadFileRepository.downloadToTempFolder(nodeHandle: nodeHandle, appData: appData, cancelToken: cancelToken, progress: update, completion: completion)
    }
    
    //MARK: - Private
    private func tempUrlFor(base64Handle: String, name: String) -> URL {
        name.mnz_isImagePathExtension ? fileCacheRepository.cachedOriginalURL(for: base64Handle, name: name) : fileCacheRepository.cachedFileURL(for: base64Handle, name: name)
    }
    
    private func shouldDownloadToGallery(name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        return name.mnz_isImagePathExtension && savePhotoInGallery || name.mnz_isVideoPathExtension && saveVideoInGallery
    }
}
