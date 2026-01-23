import MEGAUI
import Photos

public final class MockMEGAPhotoPicker: MEGAPhotoPickerProtocol {
    private let assets: [MockPHAsset]
    
    public init(assets: [MockPHAsset] = []) {
        self.assets = assets
    }
    
    public func pickAssets() async -> (assets: [PHAsset], selectedCount: Int) {
        (assets, assets.count)
    }
}

public final class MockPHAsset: PHAsset, @unchecked Sendable {}
