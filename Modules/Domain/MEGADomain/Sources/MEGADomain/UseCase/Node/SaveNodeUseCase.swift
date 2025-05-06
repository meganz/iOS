import Foundation
import MEGAPreference

extension Notification.Name {
    public static let nodeSavedToOffline = Notification.Name("nz.mega.SaveNodeUseCase.nodeSavedToOffline")
}

public protocol SaveNodeUseCaseProtocol: Sendable {
    func saveNode(from transfer: TransferEntity) async -> Bool
}

/// When saving media node (photo/video) to Photos, in case of failure we'd like to give user a chance to make that node to offline so they can access later rather than just showing error.
/// This `SaveMediaToPhotoFailureHandling` is to delegate all UI and related logic to other layers since it's not a concern of Domain layer
@objc public protocol SaveMediaToPhotoFailureHandling: Sendable {
    /// Check if we should move node to offline
    /// - Returns: return true to indicate that node should be moved to offline. Otherwise, don't
    func shouldFallbackToMakingOffline() async -> Bool
}

public struct SaveNodeUseCase<U: OfflineFilesRepositoryProtocol, V: FileCacheRepositoryProtocol, W: NodeRepositoryProtocol, Y: PhotosLibraryRepositoryProtocol, M: MediaUseCaseProtocol, P: PreferenceUseCaseProtocol, T: TransferInventoryRepositoryProtocol, X: FileSystemRepositoryProtocol, Z: SaveMediaToPhotoFailureHandling>: SaveNodeUseCaseProtocol {
    
    private let offlineFilesRepository: U
    private let fileCacheRepository: V
    private let nodeRepository: W
    private let photosLibraryRepository: Y
    private let mediaUseCase: M
    private let transferInventoryRepository: T
    private let fileSystemRepository: X
    private let saveMediaToPhotoFailureHandler: Z
    private let notificationCenter: NotificationCenter
    
    @PreferenceWrapper(key: PreferenceKeyEntity.savePhotoToGallery, defaultValue: false)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.saveVideoToGallery, defaultValue: false)
    private var saveVideoInGallery: Bool
    
    public init(offlineFilesRepository: U,
                fileCacheRepository: V,
                nodeRepository: W,
                photosLibraryRepository: Y,
                mediaUseCase: M,
                preferenceUseCase: P,
                transferInventoryRepository: T,
                fileSystemRepository: X,
                saveMediaToPhotoFailureHandler: Z,
                notificationCenter: NotificationCenter = .default
    ) {
        self.offlineFilesRepository = offlineFilesRepository
        self.fileCacheRepository = fileCacheRepository
        self.nodeRepository = nodeRepository
        self.photosLibraryRepository = photosLibraryRepository
        self.mediaUseCase = mediaUseCase
        self.transferInventoryRepository = transferInventoryRepository
        self.fileSystemRepository = fileSystemRepository
        self.saveMediaToPhotoFailureHandler = saveMediaToPhotoFailureHandler
        self.notificationCenter = notificationCenter
        $savePhotoInGallery.useCase = preferenceUseCase
        $saveVideoInGallery.useCase = preferenceUseCase
    }
    
    public func saveNode(from transfer: TransferEntity) async -> Bool {
        guard let name = transfer.fileName, let transferUrl = urlForTransfer(transfer: transfer, nodeName: name) else {
            return false
        }

        if savePhotoInGallery && mediaUseCase.isImage(name) || saveVideoInGallery && mediaUseCase.isVideo(name) || transferInventoryRepository.isSaveToPhotosAppTransfer(transfer) {
            do {
                try await photosLibraryRepository.copyMediaFileToPhotos(at: transferUrl)
                return true
            } catch {
                guard await saveMediaToPhotoFailureHandler.shouldFallbackToMakingOffline() else {
                    return false
                }
                
                await self.moveFileToOffline(name: name, transferUrl: transferUrl, nodeHandle: transfer.nodeHandle)
                return false
            }
        } else {
            await createOfflineFile(name: name, nodeHandle: transfer.nodeHandle)
            return false
        }
    }
    
    private func urlForTransfer(transfer: TransferEntity, nodeName: String) -> URL? {
        guard let transferPath = transfer.path else {
            return nil
        }
        
        if transferInventoryRepository.isSaveToPhotosAppTransfer(transfer) {
            return URL(fileURLWithPath: transferPath)
        } else if fileCacheRepository.offlineFileURL(name: nodeName).path.contains(transferPath) {
            return fileCacheRepository.offlineFileURL(name: nodeName)
        } else {
            return nil
        }
    }
    
    private func moveFileToOffline(name: String, transferUrl: URL, nodeHandle: HandleEntity) async {
        let offlineURL = fileCacheRepository.offlineFileURL(name: name)
        guard fileSystemRepository.moveFile(at: transferUrl, to: offlineURL) else { return }
        await createOfflineFile(name: name, nodeHandle: nodeHandle)
    }
    
    @MainActor
    private func createOfflineFile(name: String, nodeHandle: HandleEntity) async {
        offlineFilesRepository.createOfflineFile(name: name, for: nodeHandle)
        notificationCenter.post(name: .nodeSavedToOffline, object: nodeRepository.nodeForHandle(nodeHandle))
    }
}
