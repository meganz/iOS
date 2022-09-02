
public protocol UploadPhotoAssetsUseCaseProtocol {

    /// Upload from photo albums
    /// - Parameters:
    ///   - photoIdentifiers: The photo identifiers that when selecting from photo album.
    ///   - parentHandle: The uploading target node's handle.
    func upload(photoIdentifiers: [String], to parentHandle: HandleEntity)
}

public final class UploadPhotoAssetsUseCase: UploadPhotoAssetsUseCaseProtocol {

    private let uploadFromAlbumRepository: UploadPhotoAssetsRepositoryProtocol

    public init(uploadPhotoAssetsRepository: UploadPhotoAssetsRepositoryProtocol) {
        self.uploadFromAlbumRepository = uploadPhotoAssetsRepository
    }
    
    public func upload(photoIdentifiers: [String], to parentHandle: HandleEntity) {
        uploadFromAlbumRepository.upload(assets: photoIdentifiers, toParent: parentHandle)
    }
}
