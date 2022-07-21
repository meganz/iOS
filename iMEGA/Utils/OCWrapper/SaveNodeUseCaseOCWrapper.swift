
@objc class SaveNodeUseCaseOCWrapper: NSObject {
    let saveNodeUseCase = SaveNodeUseCase(
        offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdkManager.sharedMEGASdk()),
        fileCacheRepository: FileCacheRepository.newRepo,
        nodeRepository: NodeRepository.newRepo,
        photosLibraryRepository: PhotosLibraryRepository.newRepo)
    
    @objc func saveNodeIfNeeded(from transfer: MEGATransfer) {
        saveNodeUseCase.saveNodeIfNeeded(from: TransferEntity(transfer: transfer))
    }
}
