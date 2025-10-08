import Foundation
import MEGASwift

public protocol PhotoLibraryThumbnailRepositoryProtocol: Sendable {
    
    /// Fetches a thumbnail image as raw data for a given asset identifier.
    ///
    /// Implementations should use `PHCachingImageManager` to retrieve the thumbnail
    /// at the specified target size. If the image has been cached, the cached result
    /// should be returned to improve performance.
    ///
    /// - Parameters:
    ///   - identifier: The local identifier of the photo asset to fetch.
    ///   - targetSize: The target size (in points) for the thumbnail image.
    ///   - compressionQuality: The desired JPEG compression quality (0.0 = maximum compression,
    ///     1.0 = best quality).
    /// - Returns: An `AnyAsyncSequence` of `PhotoLibraryThumbnailResultEntity` containing
    ///   the thumbnail image data in JPEG format, or `nil` if the asset cannot be fetched
    ///   or converted.
    func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>?
    
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
