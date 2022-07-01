import Foundation

protocol UploadPhotoAssetsUseCaseProtocol {

    /// Upload from photo albums
    /// - Parameters:
    ///   - photoIdentifiers: The photo identifiers that when selecting from photo album.
    ///   - parentHandle: The uploading target node's handle.
    func upload(photoIdentifiers: [String], to parentHandle: MEGAHandle)
}

final class UploadPhotoAssetsUseCase: UploadPhotoAssetsUseCaseProtocol {

    private let uploadFromAlbumRepository: UploadPhotoAssetsRepositoryProtocol

    init(uploadPhotoAssetsRepository: UploadPhotoAssetsRepositoryProtocol) {
        self.uploadFromAlbumRepository = uploadPhotoAssetsRepository
    }
    
    func upload(photoIdentifiers: [String], to parentHandle: MEGAHandle) {
        uploadFromAlbumRepository.upload(assets: photoIdentifiers, toParent: parentHandle)
    }
}
