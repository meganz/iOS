import Photos
import UIKit

public protocol SaveSnapshotUseCaseProtocol: Sendable {
    @MainActor
    func saveToPhotoLibrary(_ image: UIImage) async -> Bool
}

public final class SaveSnapshotUseCase: SaveSnapshotUseCaseProtocol {
    private let photoLibrary: PHPhotoLibrary

    public init(photoLibrary: PHPhotoLibrary = .shared()) {
        self.photoLibrary = photoLibrary
    }

    @MainActor
    public func saveToPhotoLibrary(_ image: UIImage) async -> Bool {
        do {
            try photoLibrary.performChangesAndWait {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            return true
        } catch {
            return false
        }
    }
}
