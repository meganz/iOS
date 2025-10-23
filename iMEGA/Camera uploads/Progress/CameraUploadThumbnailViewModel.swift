import MEGAAssets
import MEGADomain
import MEGASwift

@MainActor
final class CameraUploadThumbnailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var thumbnailImage: UIImage?
    
    // MARK: - Private Properties
    private let assetIdentifier: String
    private let photoLibraryThumbnailUseCase: any PhotoLibraryThumbnailUseCaseProtocol
    private let placeholderFileExtension: String?
    private let compressionQuality: CGFloat
    
    // MARK: - Internal Properties
    let thumbnailSize: CGSize
    
    nonisolated init(
        assetIdentifier: String,
        thumbnailSize: CGSize,
        photoLibraryThumbnailUseCase: any PhotoLibraryThumbnailUseCaseProtocol,
        placeholderFileExtension: String? = nil,
        compressionQuality: CGFloat = 1.0
    ) {
        self.assetIdentifier = assetIdentifier
        self.photoLibraryThumbnailUseCase = photoLibraryThumbnailUseCase
        self.thumbnailSize = thumbnailSize
        self.placeholderFileExtension = placeholderFileExtension
        self.compressionQuality = compressionQuality
    }
    
    func loadThumbnail() async {
        guard let thumbnailDataAsyncSequence = photoLibraryThumbnailUseCase.thumbnailData(
            for: assetIdentifier, targetSize: thumbnailSize, compressionQuality: compressionQuality) else {
            loadDefaultThumbnail()
            return
        }
        
        do {
            for try await photoThumbnailImage in makeImageSequence(thumbnailDataAsyncSequence: thumbnailDataAsyncSequence) {
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
    
    private func makeImageSequence(
        thumbnailDataAsyncSequence: AnyAsyncThrowingSequence<PhotoLibraryThumbnailResultEntity, any Error>
    ) -> AnyAsyncThrowingSequence<PhotoThumbnailImage, any Error> {
        thumbnailDataAsyncSequence
            .compactMap { thumbnailDataResult async -> PhotoThumbnailImage? in
                guard !Task.isCancelled else { return nil }
                
                let image = await Task.detached(priority: .utility) {
                    UIImage(data: thumbnailDataResult.data)
                }.value
                
                guard !Task.isCancelled, let image else { return nil }
                
                return .init(
                    image: image,
                    isDegraded: thumbnailDataResult.isDegraded)
            }
            .eraseToAnyAsyncThrowingSequence()
    }
}

private struct PhotoThumbnailImage {
    let image: UIImage
    let isDegraded: Bool
}
