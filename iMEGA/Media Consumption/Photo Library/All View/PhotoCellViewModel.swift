import Foundation

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    @Published var thumbnailURL: URL?
    var thumbnailPlaceholderFileType: MEGAFileType
    
    init(photo: NodeEntity,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photo = photo
        self.thumbnailUseCase = thumbnailUseCase
        thumbnailPlaceholderFileType = thumbnailUseCase.thumbnailPlaceholderFileType(forNodeName: photo.name)
        loadThumbnail()
    }
    
    func loadThumbnail() {
        thumbnailUseCase
            .getCachedThumbnail(for: photo.handle)
            .map(Optional.some)
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailURL)
    }
}
