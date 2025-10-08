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
    ///   - targetSize: The target size (in points) for the thumbnail image.
    ///   - compressionQuality: The desired JPEG compression quality (0.0 = maximum compression,
    ///     1.0 = best quality).
    /// - Returns: An `AnyAsyncSequence` of `PhotoLibraryThumbnailResultEntity` containing
    ///   the thumbnail image data in JPEG format, or `nil` if the asset cannot be fetched
    ///   or converted.
    func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>?
}

public struct PhotoLibraryThumbnailUseCase: PhotoLibraryThumbnailUseCaseProtocol {
    private let photoLibraryThumbnailRepository: any PhotoLibraryThumbnailRepositoryProtocol
    
    public init(photoLibraryThumbnailRepository: some PhotoLibraryThumbnailRepositoryProtocol) {
        self.photoLibraryThumbnailRepository = photoLibraryThumbnailRepository
    }
    
    public func thumbnailData(for identifier: String, targetSize: CGSize, compressionQuality: CGFloat) -> AnyAsyncSequence<PhotoLibraryThumbnailResultEntity>? {
        photoLibraryThumbnailRepository.thumbnailData(
            for: identifier, targetSize: targetSize, compressionQuality: compressionQuality)
    }
}
