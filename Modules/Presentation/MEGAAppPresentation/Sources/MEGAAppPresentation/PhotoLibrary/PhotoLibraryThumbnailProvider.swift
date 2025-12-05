import MEGASwift
import Photos
import UIKit

public protocol PhotoLibraryThumbnailProviderProtocol: Sendable {
    
    /// Fetches a thumbnail image as raw data for a given asset identifier.
    ///
    /// This method retrieves a thumbnail image for a photo asset using the provided identifier.
    /// It supports asynchronous streaming of thumbnail results, which can include degraded or full-quality images.
    ///
    /// - Parameters:
    ///   - identifier: The local identifier of the photo asset to fetch.
    ///   - targetSize: The desired size of the thumbnail in points. The actual returned image
    ///     may differ slightly depending on system scaling and asset availability.
    /// - Returns: An optional `AnyAsyncThrowingSequence` of `PhotoLibraryThumbnailResultEntity`.
    ///   The sequence yields one or more thumbnail results as the image is prepared. Returns
    ///   `nil` if the asset cannot be fetched or converted to JPEG.
    func thumbnail(for identifier: String, targetSize: CGSize) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResult, any Error>?
    
    /// Starts caching thumbnails for the given asset identifiers.
    ///
    /// Implementations should preload and cache images at the specified target size
    /// to speed up future thumbnail requests.
    ///
    /// - Parameters:
    ///   - identifiers: The asset identifiers to begin caching.
    ///   - targetSize: The size of thumbnails to cache.
    func startCaching(for identifiers: [String], targetSize: CGSize)
    
    /// Stops caching thumbnails for the given asset identifiers.
    ///
    /// Implementations should remove cached thumbnails corresponding to the provided
    /// identifiers and target size, freeing up memory.
    ///
    /// - Parameters:
    ///   - identifiers: The asset identifiers to stop caching.
    ///   - targetSize: The size of thumbnails to stop caching.
    func stopCaching(for identifiers: [String], targetSize: CGSize)
    
    /// Clears all cached thumbnails.
    ///
    /// Implementations should release any resources held by the image manager’s cache.
    func clearCache()
}

public struct PhotoLibraryThumbnailProvider: PhotoLibraryThumbnailProviderProtocol {
    private let imageManager: PHCachingImageManager
    
    public init(imageManager: PHCachingImageManager = PHCachingImageManager()) {
        self.imageManager = imageManager
    }
    
    public func thumbnail(for identifier: String, targetSize: CGSize) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResult, any Error>? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier],
                                              options: fetchOptions()).firstObject else { return nil }
        
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: PhotoLibraryThumbnailResult.self)
        
        let requestId = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: thumbnailOptions()
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
            
            if let image {
                continuation.yield(.init(image: image, isDegraded: isDegraded))
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
        
        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: thumbnailOptions()
        )
    }
    
    public func stopCaching(for identifiers: [String], targetSize: CGSize) {
        let assets = fetchAssets(for: identifiers)
        guard assets.isNotEmpty else { return }
        
        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: thumbnailOptions()
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
    
    private func thumbnailOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.version = .current
        return options
    }
}
