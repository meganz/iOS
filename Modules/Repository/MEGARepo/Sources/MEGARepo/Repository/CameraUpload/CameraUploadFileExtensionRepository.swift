import MEGADomain
@preconcurrency import Photos

public struct CameraAssetTypeRepository: CameraAssetTypeRepositoryProtocol {
    
    public init() { }
    
    public func loadAssetType(for localIdentifier: String) -> AssetMediaTypeEntity? {
        let options = PHFetchOptions()
        options.fetchLimit = 1

        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: options)
        guard let asset = fetch.firstObject else { return nil }

        let isBurst = !(asset.burstIdentifier?.isEmpty ?? true)
        let utType = firstUTType(
            for: PHAssetResource.assetResources(for: asset))

        let mediaFormat = utType?.toAssetMediaFormatEntity() ?? .unknown(identifier: utType?.identifier ?? "")

        return AssetMediaTypeEntity(
            mediaFormat: mediaFormat,
            isBurst: isBurst)
    }
    
    private func firstUTType(for resources: [PHAssetResource]) -> UTType? {
        if #available(iOS 26.0, *) {
            return resources.first?.contentType
        }
        
        return resources.lazy
            .compactMap { UTType($0.uniformTypeIdentifier) }
            .first
    }
}
