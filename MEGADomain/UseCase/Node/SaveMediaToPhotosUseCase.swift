
protocol SaveMediaToPhotosUseCaseProtocol {
    func saveToPhotos(node: NodeEntity, cancelToken: MEGACancelToken, completion: @escaping (SaveMediaToPhotosErrorEntity?) -> Void)
    func saveToPhotosChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, cancelToken: MEGACancelToken, completion: @escaping (SaveMediaToPhotosErrorEntity?) -> Void)
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
    
    func saveToPhotos(node: NodeEntity, cancelToken: MEGACancelToken, completion: @escaping (SaveMediaToPhotosErrorEntity?) -> Void) {
        let tempUrl = fileCacheRepository.cachedFileURL(for: node.base64Handle, name: node.name)
       
        downloadFileRepository.download(nodeHandle: node.handle, to: tempUrl.path, appData: NSString().mnz_appDataToSaveInPhotosApp(), cancelToken: cancelToken) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure:
                completion(.downloadFailed)
            }
        }
    }
    
    func saveToPhotosChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle, cancelToken: MEGACancelToken, completion: @escaping  (SaveMediaToPhotosErrorEntity?) -> Void) {
        guard let base64Handle = nodeRepository.base64ForChatNode(handle: handle, messageId: messageId, chatId: chatId), let name = nodeRepository.nameForChatNode(handle: handle, messageId: messageId, chatId: chatId) else {
            completion(.downloadFailed)
            return
        }

        let tempUrl = fileCacheRepository.cachedFileURL(for: base64Handle, name: name)
        
        downloadFileRepository.downloadChat(nodeHandle: handle, messageId: messageId, chatId: chatId, to: tempUrl.path, appData: NSString().mnz_appDataToSaveInPhotosApp(), cancelToken: cancelToken) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure:
                completion(.downloadFailed)
            }
        }
    }
}
