import MEGADomain
import MEGASwift
import Photos

public struct PhotoLibraryThumbnailRepository: PhotoLibraryThumbnailRepositoryProtocol {
    private let imageManager: PHCachingImageManager
    
    public init(imageManager: PHCachingImageManager = PHCachingImageManager()) {
        self.imageManager = imageManager
    }
    
    public func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>? {
        guard let asset = fetchAsset(for: identifier) else { return nil }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        
        let (stream, continuation) = AsyncStream.makeStream(of: PhotoLibraryThumbnailResultEntity.self)
        
        let requestId = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                continuation.finish()
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
        
        return stream.eraseToAnyAsyncSequence()
    }
    
    public func startCaching(for identifiers: [String], targetSize: CGSize) {
        let assets = fetchAssets(for: identifiers)
        guard assets.isNotEmpty else { return }
        
        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: fastOptions()
        )
    }
    
    public func stopCaching(for identifiers: [String], targetSize: CGSize) {
        let assets = fetchAssets(for: identifiers)
        guard assets.isNotEmpty else { return }
        
        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: fastOptions()
        )
    }
    
    public func clearCache() {
        imageManager.stopCachingImagesForAllAssets()
    }
    
    private func fetchAsset(for identifier: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }
    
    private func fetchAssets(for identifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }
    
    private func fastOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        return options
    }
}
