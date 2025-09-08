import Foundation
import MEGAVideoPlayer
import UIKit

@MainActor
public final class MockSaveSnapshotUseCase: SaveSnapshotUseCaseProtocol {
    public var saveToPhotoLibraryCallCount: Int = 0
    public var savedImage: UIImage?
    public var saveResult: Bool = true
    
    public init() {}
    
    @MainActor
    public func saveToPhotoLibrary(_ image: UIImage) async -> Bool {
        saveToPhotoLibraryCallCount += 1
        savedImage = image
        return saveResult
    }
}
