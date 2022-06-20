
@objc class SaveNodeUseCaseOCWrapper: NSObject {
    let saveNodeUseCase = SaveNodeUseCase(
        offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdkManager.sharedMEGASdk()),
        fileCacheRepository: FileCacheRepository.default,
        nodeRepository: NodeRepository.default,
        photosLibraryRepository: PhotosLibraryRepository())
    
    @objc func saveNodeIfNeeded(from transfer: MEGATransfer) {
        saveNodeUseCase.saveNodeIfNeeded(from: TransferEntity(transfer: transfer))
    }
}
