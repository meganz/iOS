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
    
    public func pickAssets() async -> (assets: [PHAsset], selectedCount: Int) {
        (assets, assets.count)
    }
    
    public func pickResults() async -> [PHPickerResult] {
        results
    }
}

public final class MockPHAsset: PHAsset, @unchecked Sendable {}
