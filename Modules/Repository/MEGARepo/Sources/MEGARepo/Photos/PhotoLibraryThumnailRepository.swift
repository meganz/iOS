import MEGADomain
import MEGASwift
import Photos

public struct PhotoLibraryThumbnailRepository: PhotoLibraryThumbnailRepositoryProtocol {
    private let imageManager: PHCachingImageManager
    
    public init(imageManager: PHCachingImageManager = PHCachingImageManager()) {
        self.imageManager = imageManager
    }
    
    public func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier],
                                              options: fetchOptions()).firstObject else { return nil }
        
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: PhotoLibraryThumbnailResultEntity.self)
        
        let requestId = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptionsForAsset(asset)
        ) { image, info in
            if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                continuation.finish()
                return
            }
            
            if let error = info?[PHImageErrorKey] as? any Error {
                continuation.finish(throwing: error)
                return
            }
            
            let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            
            if let image,
               let data = image.jpegData(compressionQuality: compressionQuality) {
                continuation.yield(.init(data: data, isDegraded: isDegraded))
            }
            
            if !isDegraded {
                continuation.finish()
            }
        }
        
        continuation.onTermination = { _ in
            imageManager.cancelImageRequest(requestId)
        }
        
        return stream.eraseToAnyAsyncThrowingSequence()
    }
    
    public func startCaching(for identifiers: [String], targetSize: CGSize) {
        let assets = fetchAssets(for: identifiers)
        guard assets.isNotEmpty else { return }
        
        let options = generalCacheOptions()
        
        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
    }
    
    public func stopCaching(for identifiers: [String], targetSize: CGSize) {
        let assets = fetchAssets(for: identifiers)
        guard assets.isNotEmpty else { return }
        
        let options = generalCacheOptions()
        
        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
    }
    
    public func clearCache() {
        imageManager.stopCachingImagesForAllAssets()
    }
    
    private func fetchAssets(for identifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: fetchOptions())
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }
    
    private func fetchOptions() -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared]
        fetchOptions.includeHiddenAssets = false
        fetchOptions.predicate = NSPredicate(
            format: "mediaType IN %@", [PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue])
        return fetchOptions
    }
    
    private func generalCacheOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.version = .current
        return options
    }
    
    private func requestOptionsForAsset(_ asset: PHAsset) -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        if asset.mediaSubtypes.contains(.photoLive) {
            options.version = .current
        }
        if asset.mediaType == .video {
            options.deliveryMode = .opportunistic
        }
        return options
    }
}
