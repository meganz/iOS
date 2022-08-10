import MEGADomain

protocol SaveMediaToPhotosUseCaseProtocol {
    func saveToPhotos(node: NodeEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void)
    func saveToPhotos(fileLink: FileLinkEntity) async throws
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
        let tempUrl = fileCacheRepository.cachedFileURL(for: node.base64Handle, name: node.name)
       
        downloadFileRepository.download(nodeHandle: node.handle, to: tempUrl.path, appData: NSString().mnz_appDataToSaveInPhotosApp(), cancelToken: nil) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
            }
        }
    }
    
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void) {
        guard let base64Handle = nodeRepository.base64ForChatNode(handle: handle, messageId: messageId, chatId: chatId), let name = nodeRepository.nameForChatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let tempUrl = fileCacheRepository.cachedFileURL(for: base64Handle, name: name)
        
        downloadFileRepository.downloadChat(nodeHandle: handle, messageId: messageId, chatId: chatId, to: tempUrl.path, appData: NSString().mnz_appDataToSaveInPhotosApp(), cancelToken: nil) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(error == TransferErrorEntity.cancelled ? .cancelled : .downloadFailed))
            }
        }
    }
    
    func saveToPhotos(fileLink: FileLinkEntity) async throws {
        let node = try await nodeRepository.nodeFor(fileLink: fileLink)
        let transferMetaData = TransferMetaDataEntity(metaData: NSString().mnz_appDataToSaveInPhotosApp())
        _ = try await downloadFileRepository.downloadFileLink(fileLink, named: node.name, toUrl: fileCacheRepository.tempURL(for: node.base64Handle), transferMetaData: transferMetaData, startFirst: true, cancelToken: nil)
    }
}
