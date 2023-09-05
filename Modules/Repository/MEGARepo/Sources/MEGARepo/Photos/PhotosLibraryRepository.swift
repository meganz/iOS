import MEGADomain
import Photos

public struct PhotosLibraryRepository: PhotosLibraryRepositoryProtocol {
    public static var newRepo: PhotosLibraryRepository {
        PhotosLibraryRepository()
    }

    private let options: PHAssetResourceCreationOptions = {
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = true
        return options
    }()

    private let library = PHPhotoLibrary.shared()

    public func copyMediaFileToPhotos(at url: URL, completion: ((SaveMediaToPhotosErrorEntity?) -> Void)?) {
        let type: PHAssetResourceType = url.fileExtensionGroup.isImage ? .photo : .video
        library.performChanges {
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
