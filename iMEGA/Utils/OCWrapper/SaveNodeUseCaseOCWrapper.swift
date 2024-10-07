import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo

@objc class SaveNodeUseCaseOCWrapper: NSObject {
    private let saveNodeUseCase: any SaveNodeUseCaseProtocol
        
    @objc init(saveMediaToPhotoFailureHandler: any SaveMediaToPhotoFailureHandling) {
        self.saveNodeUseCase = SaveNodeUseCase(
            offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdk.shared),
            fileCacheRepository: FileCacheRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            photosLibraryRepository: PhotosLibraryRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            preferenceUseCase: PreferenceUseCase.default,
            transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.shared), fileSystemRepository: FileSystemRepository.newRepo,
            saveMediaToPhotoFailureHandler: saveMediaToPhotoFailureHandler
        )
        super.init()
    }
    
    @objc func saveNodeIfNeeded(from transfer: MEGATransfer) {
        saveNodeUseCase.saveNode(from: transfer.toTransferEntity()) { result in
            Task { [weak self] in
                await self?.handleSaveNodeResult(result)
            }
        }
    }
    
    private nonisolated func handleSaveNodeResult(_ result: Result<Bool, SaveMediaToPhotosErrorEntity>) async {
        switch result {
        case .success(let savedToPhotos):
            let transferInventoryUseCase = TransferInventoryUseCase(
                transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.shared), fileSystemRepository: FileSystemRepository.newRepo)
            let anyPendingSavePhotosTransfer = transferInventoryUseCase.saveToPhotosTransfers(filteringUserTransfer: true)?.isNotEmpty ?? false
            if savedToPhotos, !anyPendingSavePhotosTransfer {
                await SVProgressHUD.show(UIImage.saveToPhotos, status: Strings.Localizable.savedToPhotos)
            }
        case .failure(let error):
            switch error {
            case .videoNotSaved, .imageNotSaved:
                await SVProgressHUD.showError(withStatus: Strings.Localizable.couldNotSaveItem)
            default:
                await SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
            }
        }
    }
}
