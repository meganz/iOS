import Foundation
import Photos
import MobileCoreServices
import MEGADomain

extension PHAsset {
    
    @objc var mnz_livePhotoResource: PHAssetResource? {
        searchResource(by: [.fullSizePairedVideo, .pairedVideo, .adjustmentBasePairedVideo])
    }
    
    var mnz_rawImageResource: PHAssetResource? {
        searchResource(by: [.photo, .alternatePhoto])
    }
    
    /// Search `PHAssetResource` from the current asset
    /// - Parameter types: `PHAssetResourceType` search list
    /// - Returns: It returns the first found asset resource according to the type search list
    private func searchResource(by types: [PHAssetResourceType]) -> PHAssetResource? {
        for type in types {
            for resource in PHAssetResource.assetResources(for: self) where resource.type == type {
                return resource
            }
        }
        
        return nil
    }
    
    /// Check if the current asset is a raw image or not
    @objc var mnz_isRawImage: Bool {
        guard let resource = searchResource(by: [.photo, .alternatePhoto]) else {
            return mediaType == .image && mediaSubtypes.contains(.mnz_rawImage)
        }
        
        return UTTypeConformsTo(resource.uniformTypeIdentifier as CFString, kUTTypeRawImage)
    }
    
    @objc var mnz_isLivePhoto: Bool {
        mediaType == .image && mediaSubtypes.contains(.photoLive)
    }
    
    @objc func mnz_fileExtension(fromAssetInfo info: [AnyHashable: Any]?, uniformTypeIdentifier uti: String?) -> FileExtension {
        let urlString = info?["PHImageFileURLKey"] as? String
        let url = urlString.flatMap { URL(string: $0) }
        
        var dataUTI = uti
        if dataUTI == nil {
            dataUTI = info?["PHImageFileUTIKey"] as? String
        }
        
        return GetFileExtensionUseCase().fileExtension(for: mediaType.toMediaTypeEntity(),
                                                       url: url,
                                                       uniformTypeIdentifier: dataUTI)
    }
}
