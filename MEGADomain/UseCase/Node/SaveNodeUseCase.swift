
protocol SaveNodeUseCaseProtocol {
    func saveNodeIfNeeded(from transfer: TransferEntity)
}

struct SaveNodeUseCase<U: OfflineFilesRepositoryProtocol, V: FileCacheRepositoryProtocol, W: NodeRepositoryProtocol, Y: PhotosLibraryRepositoryProtocol>: SaveNodeUseCaseProtocol {
    
    private let offlineFilesRepository: U
    private let fileCacheRepository: V
    private let nodeRepository: W
    private let photosLibraryRepository: Y

    @PreferenceWrapper(key: .savePhotoToGallery, defaultValue: false, useCase: PreferenceUseCase.default)
    private var savePhotoInGallery: Bool
    @PreferenceWrapper(key: .saveVideoToGallery, defaultValue: false, useCase: PreferenceUseCase.default)
    private var saveVideoInGallery: Bool
    
    init(offlineFilesRepository: U, fileCacheRepository: V, nodeRepository: W, photosLibraryRepository: Y) {
        self.offlineFilesRepository = offlineFilesRepository
        self.fileCacheRepository = fileCacheRepository
        self.nodeRepository = nodeRepository
        self.photosLibraryRepository = photosLibraryRepository
    }
    
    func saveNodeIfNeeded(from transfer: TransferEntity) {
        guard let name = transfer.fileName, let transferUrl = urlForTransfer(transfer: transfer, nodeName: name) else {
            return
        }
        
        setCoordinates(nodeHandle: transfer.nodeHandle, fromFileAt: transferUrl.path)

        if savePhotoInGallery && name.mnz_isImagePathExtension || saveVideoInGallery && name.mnz_isVideoPathExtension || transfer.appData?.contains(NSString().mnz_appDataToSaveInPhotosApp()) ?? false {
            photosLibraryRepository.copyMediaFileToPhotos(at: transferUrl) { error in
                if error == nil {
                    SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savedToPhotos)
                } else {
                    switch error {
                    case .videoNotSaved, .imageNotSaved:
                        SVProgressHUD.showError(withStatus: Strings.Localizable.couldNotSaveItem)
                    default:
                        SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
                    }
                }
            }
        } else {
            offlineFilesRepository.createOfflineFile(name: name, for: transfer.nodeHandle)
        }
    }
    
    private func urlForTransfer(transfer: TransferEntity, nodeName: String) -> URL? {
        guard let transferPath = transfer.path else {
            return nil
        }
        
        if transfer.appData?.contains(NSString().mnz_appDataToSaveInPhotosApp()) ?? false {
            return URL(fileURLWithPath: transferPath)
        } else if fileCacheRepository.offlineFileURL(name: nodeName).path.contains(transferPath) {
            return fileCacheRepository.offlineFileURL(name: nodeName)
        } else {
            return nil
        }
    }
    
    private func setCoordinates(nodeHandle: HandleEntity, fromFileAt path: String) {
        guard let mediaCoordinates = path.mnz_coordinatesOfPhotoOrVideo() else {
            return
        }
        
        let coordinatesArray = mediaCoordinates.components(separatedBy: "&")
        
        guard coordinatesArray.count == 2, let latitude = Double(coordinatesArray[0]), let longitude = Double(coordinatesArray[1]) else {
            return
        }
        
        nodeRepository.setNodeCoordinates(nodeHandle: nodeHandle, latitude: latitude, longitude: longitude)
    }
}
