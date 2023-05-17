import Photos
import MEGADomain

struct PhotosLibraryRepository: PhotosLibraryRepositoryProtocol {
    static var newRepo: PhotosLibraryRepository {
        PhotosLibraryRepository()
    }
    
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
        } completionHandler: { success, _ in
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
