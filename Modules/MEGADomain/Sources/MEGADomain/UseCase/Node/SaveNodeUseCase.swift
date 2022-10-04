import Foundation

public protocol SaveNodeUseCaseProtocol {
    func saveNode(from transfer: TransferEntity, completion: @escaping (Result<Bool, SaveMediaToPhotosErrorEntity>) -> Void)
}

public struct SaveNodeUseCase<U: OfflineFilesRepositoryProtocol, V: FileCacheRepositoryProtocol, W: NodeRepositoryProtocol, Y: PhotosLibraryRepositoryProtocol, M: MediaUseCaseProtocol, P: PreferenceUseCaseProtocol>: SaveNodeUseCaseProtocol {
    
    private let offlineFilesRepository: U
    private let fileCacheRepository: V
    private let nodeRepository: W
    private let photosLibraryRepository: Y
    private let mediaUseCase: M

    @PreferenceWrapper(key: .savePhotoToGallery, defaultValue: false)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: .saveVideoToGallery, defaultValue: false)
    private var saveVideoInGallery: Bool
    
    public init(offlineFilesRepository: U, fileCacheRepository: V, nodeRepository: W, photosLibraryRepository: Y, mediaUseCase: M, preferenceUseCase: P) {
        self.offlineFilesRepository = offlineFilesRepository
        self.fileCacheRepository = fileCacheRepository
        self.nodeRepository = nodeRepository
        self.photosLibraryRepository = photosLibraryRepository
        self.mediaUseCase = mediaUseCase
        $savePhotoInGallery.useCase = preferenceUseCase
        $saveVideoInGallery.useCase = preferenceUseCase
    }
    
    public func saveNode(from transfer: TransferEntity, completion: @escaping (Result<Bool, SaveMediaToPhotosErrorEntity>) -> Void) {
        guard let name = transfer.fileName, let transferUrl = urlForTransfer(transfer: transfer, nodeName: name) else {
            completion(.success(false))
            return
        }

        if savePhotoInGallery && mediaUseCase.isImage(name) || saveVideoInGallery && mediaUseCase.isVideo(name) || transfer.appData?.contains(AppDataEntity.saveInPhotos.rawValue) ?? false {
            photosLibraryRepository.copyMediaFileToPhotos(at: transferUrl) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        } else {
            offlineFilesRepository.createOfflineFile(name: name, for: transfer.nodeHandle)
            completion(.success(false))
        }
    }
    
    private func urlForTransfer(transfer: TransferEntity, nodeName: String) -> URL? {
        guard let transferPath = transfer.path else {
            return nil
        }
        
        if transfer.appData?.contains(AppDataEntity.saveInPhotos.rawValue) ?? false {
            return URL(fileURLWithPath: transferPath)
        } else if fileCacheRepository.offlineFileURL(name: nodeName).path.contains(transferPath) {
            return fileCacheRepository.offlineFileURL(name: nodeName)
        } else {
            return nil
        }
    }
}
