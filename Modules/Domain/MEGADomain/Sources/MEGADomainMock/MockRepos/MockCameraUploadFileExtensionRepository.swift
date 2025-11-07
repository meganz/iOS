import MEGADomain

public struct MockCameraAssetTypeRepository: CameraAssetTypeRepositoryProtocol {
    private let assetMediaType: AssetMediaTypeEntity?
    
    public init(assetMediaType: AssetMediaTypeEntity? = nil) {
        self.assetMediaType = assetMediaType
    }
    
    public func loadAssetType(for localIdentifier: String) -> AssetMediaTypeEntity? {
        assetMediaType
    }
}
