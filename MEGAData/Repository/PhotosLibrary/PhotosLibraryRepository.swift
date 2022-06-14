
import Photos

struct PhotosLibraryRepository: PhotosLibraryRepositoryProtocol {
    
    var completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?
    let options: PHAssetResourceCreationOptions = {
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = true
        return options
    }()
    
    func copyMediaFileToPhotos(at url: URL, completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?) {
        let type: PHAssetResourceType = url.lastPathComponent.mnz_isImagePathExtension ? .photo : .video
        PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: type, fileURL: url, options: self.options)
        } completionHandler: { success, error in
            if success {
                completion?(nil)
            } else {
                switch type {
                case .photo:
                    completion?(.imageNotSaved)
                case .video:
                    completion?(.videoNotSaved)
                default:
                    completion?(.wrongExtensionFormat)
                }
            }
        }
    }
}
