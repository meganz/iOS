import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift

@MainActor
final class CameraUploadThumbnailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var thumbnailImage: UIImage?
    
    // MARK: - Private Properties
    private let assetIdentifier: String
    private let photoLibraryThumbnailProvider: any PhotoLibraryThumbnailProviderProtocol
    private let placeholderFileExtension: String?
    
    // MARK: - Internal Properties
    let thumbnailSize: CGSize
    
    nonisolated init(
        assetIdentifier: String,
        thumbnailSize: CGSize,
        photoLibraryThumbnailProvider: some PhotoLibraryThumbnailProviderProtocol,
        placeholderFileExtension: String? = nil
    ) {
        self.assetIdentifier = assetIdentifier
        self.photoLibraryThumbnailProvider = photoLibraryThumbnailProvider
        self.thumbnailSize = thumbnailSize
        self.placeholderFileExtension = placeholderFileExtension
    }
    
    func loadThumbnail() async {
        guard let thumbnailDataAsyncSequence = photoLibraryThumbnailProvider.thumbnail(
            for: assetIdentifier, targetSize: thumbnailSize) else {
            loadDefaultThumbnail()
            return
        }
        
        do {
            for try await photoThumbnailImage in thumbnailDataAsyncSequence {
                try Task.checkCancellation()
                self.thumbnailImage = photoThumbnailImage.image
                if !photoThumbnailImage.isDegraded {
                    break
                }
            }
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] loadThumbnail cancelled")
        } catch {
            loadDefaultThumbnail()
            MEGALogError("[\(type(of: self))] failed to load thumbnail image: \(error)")
        }
    }
    
    private func loadDefaultThumbnail() {
        guard let placeholderFileExtension else { return }
        thumbnailImage = MEGAAssets.UIImage.image(forFileExtension: placeholderFileExtension)
    }
}
