import MEGADomain

protocol SaveMediaToPhotosUseCaseProtocol {
    func saveToPhotos(node: NodeEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
    func saveToPhotos(fileLink: FileLinkEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
}
        
struct SaveMediaToPhotosUseCase<T: DownloadFileRepositoryProtocol, U: FileCacheRepositoryProtocol, V: NodeRepositoryProtocol>: SaveMediaToPhotosUseCaseProtocol {
    private let downloadFileRepository: T
    private let fileCacheRepository: U
    private let nodeRepository: V

    init(downloadFileRepository: T,
         fileCacheRepository: U,
         nodeRepository: V) {
        self.downloadFileRepository = downloadFileRepository
        self.fileCacheRepository = fileCacheRepository
        self.nodeRepository = nodeRepository
    }
    
    func saveToPhotos(node: NodeEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        let tempUrl = fileCacheRepository.tempFileURL(for: node)
       
        downloadFileRepository.download(nodeHandle: node.handle, to: tempUrl, appData: NSString().mnz_appDataToSaveInPhotosApp(), cancelToken: nil) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
            }
        }
    }
    
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        guard let node = nodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let tempUrl = fileCacheRepository.tempFileURL(for: node)

        downloadFileRepository.downloadChat(nodeHandle: handle, messageId: messageId, chatId: chatId, to: tempUrl, appData: NSString().mnz_appDataToSaveInPhotosApp(), cancelToken: nil) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
            }
        }
    }
    
    func saveToPhotos(fileLink: FileLinkEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        let transferMetaData = TransferMetaDataEntity(metaData: NSString().mnz_appDataToSaveInPhotosApp())
        nodeRepository.nodeFor(fileLink: fileLink) { result in
            switch result {
            case .success(let node):
                downloadFileRepository.downloadFileLink(fileLink, named: node.name, to: fileCacheRepository.base64HandleTempFolder(for: node.base64Handle), transferMetaData: transferMetaData, startFirst: true, cancelToken: nil, start: nil, update: nil) { result in
                    switch result {
                    case .success(_):
                        completion(.success)
                    case .failure(let error):
                        completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
                    }
                }
            case .failure(_):
                completion(.failure(.nodeNotFound))
            }
        }
    }
}
