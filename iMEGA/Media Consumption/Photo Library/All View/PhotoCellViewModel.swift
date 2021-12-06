import Foundation

final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    @Published var thumbnailURL: URL?
    
    init(photo: NodeEntity,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photo = photo
        self.thumbnailUseCase = thumbnailUseCase
        
        loadThumbnail()
    }
    
    func loadThumbnail() {
        thumbnailUseCase.getCachedThumbnail(for: photo.handle) { [weak self] result in
            switch result {
            case .failure:
                break
            case .success(let url):
                self?.thumbnailURL = url
            }
        }
    }
}
