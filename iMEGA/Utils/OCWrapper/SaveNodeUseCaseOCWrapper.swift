import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGARepo

@objc final class SaveNodeUseCaseOCWrapper: NSObject, Sendable {
    private let saveNodeUseCase: any SaveNodeUseCaseProtocol
        
    @objc init(saveMediaToPhotoFailureHandler: any SaveMediaToPhotoFailureHandling) {
        self.saveNodeUseCase = SaveNodeUseCase(
            offlineFilesRepository: OfflineFilesRepository(
                store: MEGAStore.shareInstance(),
                sdk: MEGASdk.shared,
                folderSizeCalculator: FolderSizeCalculator()
            ),
            fileCacheRepository: FileCacheRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            photosLibraryRepository: PhotosLibraryRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            preferenceUseCase: PreferenceUseCase.default,
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo,
            saveMediaToPhotoFailureHandler: saveMediaToPhotoFailureHandler
        )
        super.init()
    }
    
    @objc func saveNodeIfNeeded(from transfer: MEGATransfer) {
        Task {
            let savedToPhotos = await saveNodeUseCase.saveNode(from: transfer.toTransferEntity())
            await handleSaveNode(savedToPhotos)
        }
    }
    
    private func handleSaveNode(_ savedToPhotos: Bool) async {
        let transferInventoryUseCase = TransferInventoryUseCase(
            transferInventoryRepository: TransferInventoryRepository.newRepo, fileSystemRepository: FileSystemRepository.sharedRepo)
        let anyPendingSavePhotosTransfer = transferInventoryUseCase.saveToPhotosTransfers(filteringUserTransfer: true)?.isNotEmpty ?? false
        if savedToPhotos, !anyPendingSavePhotosTransfer {
            await SVProgressHUD.show(MEGAAssets.UIImage.saveToPhotos, status: Strings.Localizable.savedToPhotos)
        }
    }
}
