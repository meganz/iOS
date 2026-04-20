import MEGAUI
import Photos
import PhotosUI

public final class MockMEGAPhotoPicker: MEGAPhotoPickerProtocol {
    private let assets: [MockPHAsset]
    private let results: [PHPickerResult]
    
    public init(
        assets: [MockPHAsset] = [],
        results: [PHPickerResult] = []
    ) {
        self.assets = assets
        self.results = results
    }
    
    public func pickAssets(completion: @escaping ([PHAsset], Int) -> Void) {
        completion(assets, assets.count)
    }

    public func pickResults(completion: @escaping ([PHPickerResult]) -> Void) {
        completion(results)
    }
}

public final class MockPHAsset: PHAsset, @unchecked Sendable {}
