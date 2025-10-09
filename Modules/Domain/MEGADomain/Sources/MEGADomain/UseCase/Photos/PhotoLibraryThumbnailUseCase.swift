import Foundation
import MEGASwift

public protocol PhotoLibraryThumbnailUseCaseProtocol: Sendable {
    /// Fetches a thumbnail image as raw data for a given asset identifier.
    ///
    /// This method returns an asynchronous sequence of `PhotoLibraryThumbnailResultEntity`,
    /// which may provide multiple results over time. The first result can be a low-quality
    /// image suitable for quick display, followed by higher-quality images when available.
    ///
    /// - Parameters:
    ///   - identifier: The local identifier of the photo asset to fetch.
    ///   - targetSize: The desired size of the thumbnail in points. The actual returned image
    ///     may differ slightly depending on system scaling and asset availability.
    ///   - compressionQuality: The JPEG compression quality to apply to the resulting thumbnail
    ///     image. A value of 0.0 represents maximum compression (lowest quality), and 1.0
    ///     represents best quality (least compression).
    /// - Returns: An optional `AnyAsyncThrowingSequence` of `PhotoLibraryThumbnailResultEntity`.
    ///   The sequence yields one or more thumbnail results as the image is prepared. Returns
    ///   `nil` if the asset cannot be fetched or converted to JPEG.
    func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>?
    
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

public struct PhotoLibraryThumbnailUseCase: PhotoLibraryThumbnailUseCaseProtocol {
    private let photoLibraryThumbnailRepository: any PhotoLibraryThumbnailRepositoryProtocol
    
    public init(photoLibraryThumbnailRepository: some PhotoLibraryThumbnailRepositoryProtocol) {
        self.photoLibraryThumbnailRepository = photoLibraryThumbnailRepository
    }
    
    public func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>? {
        photoLibraryThumbnailRepository.thumbnailData(
            for: identifier, targetSize: targetSize, compressionQuality: compressionQuality)
    }
    
    public func startCaching(for identifiers: [String], targetSize: CGSize) {
        photoLibraryThumbnailRepository.startCaching(for: identifiers, targetSize: targetSize)
    }

    public func stopCaching(for identifiers: [String], targetSize: CGSize) {
        photoLibraryThumbnailRepository.stopCaching(for: identifiers, targetSize: targetSize)
    }
    
    public func clearCache() {
        photoLibraryThumbnailRepository.clearCache()
    }
}
