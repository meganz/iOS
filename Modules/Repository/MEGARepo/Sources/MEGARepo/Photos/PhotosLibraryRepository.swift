import MEGADomain
@preconcurrency import Photos

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
    
    public func copyMediaFileToPhotos(at url: URL) async throws(SaveMediaToPhotosErrorEntity) {
        let type: PHAssetResourceType = url.fileExtensionGroup.isImage ? .photo : .video
        do {
            try await library.performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: type, fileURL: url, options: self.options)
            }
        } catch {
            throw switch type {
            case .photo: .imageNotSaved
            case .video: .videoNotSaved
            default: .wrongExtensionFormat
            }
        }
    }
}
