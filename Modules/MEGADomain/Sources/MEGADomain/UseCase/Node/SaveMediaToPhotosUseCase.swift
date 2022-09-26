
public protocol SaveMediaToPhotosUseCaseProtocol {
    func saveToPhotos(node: NodeEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
    func saveToPhotos(fileLink: FileLinkEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
}
        
public struct SaveMediaToPhotosUseCase<T: DownloadFileRepositoryProtocol, U: FileCacheRepositoryProtocol, V: NodeRepositoryProtocol>: SaveMediaToPhotosUseCaseProtocol {
    private let downloadFileRepository: T
    private let fileCacheRepository: U
    private let nodeRepository: V

    public init(downloadFileRepository: T,
         fileCacheRepository: U,
         nodeRepository: V) {
        self.downloadFileRepository = downloadFileRepository
        self.fileCacheRepository = fileCacheRepository
        self.nodeRepository = nodeRepository
    }
    
    public func saveToPhotos(node: NodeEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        let tempUrl = fileCacheRepository.tempFileURL(for: node)
       
        downloadFileRepository.download(nodeHandle: node.handle, to: tempUrl, appData: AppDataEntity.saveInPhotos.rawValue) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
            }
        }
    }
    
    public func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        guard let node = nodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let tempUrl = fileCacheRepository.tempFileURL(for: node)

        downloadFileRepository.downloadChat(nodeHandle: handle, messageId: messageId, chatId: chatId, to: tempUrl, appData: AppDataEntity.saveInPhotos.rawValue) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
            }
        }
    }
    
    public func saveToPhotos(fileLink: FileLinkEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        let transferMetaData = TransferMetaDataEntity(metaData: AppDataEntity.saveInPhotos.rawValue)
        nodeRepository.nodeFor(fileLink: fileLink) { result in
            switch result {
            case .success(let node):
                downloadFileRepository.downloadFileLink(fileLink, named: node.name, to: fileCacheRepository.base64HandleTempFolder(for: node.base64Handle), transferMetaData: transferMetaData, startFirst: true, start: nil, update: nil) { result in
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
