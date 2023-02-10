import MEGADomain

@objc class SaveNodeUseCaseOCWrapper: NSObject {
    let saveNodeUseCase = SaveNodeUseCase(
        offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdkManager.sharedMEGASdk()),
        fileCacheRepository: FileCacheRepository.newRepo,
        nodeRepository: NodeRepository.newRepo,
        photosLibraryRepository: PhotosLibraryRepository.newRepo,
        mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
        preferenceUseCase: PreferenceUseCase.default,
        transferRepository: TransfersRepository(sdk: MEGASdkManager.sharedMEGASdk()))
    
    @objc func saveNodeIfNeeded(from transfer: MEGATransfer) {
        saveNodeUseCase.saveNode(from:transfer.toTransferEntity()) { result in
            switch result {
            case .success(let savedToPhotos):
                if savedToPhotos {
                    SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savedToPhotos)
                }
            case .failure(let error):
                switch error {
                case .videoNotSaved, .imageNotSaved:
                    SVProgressHUD.showError(withStatus: Strings.Localizable.couldNotSaveItem)
                default:
                    SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
                }
            }
        }
    }
}
