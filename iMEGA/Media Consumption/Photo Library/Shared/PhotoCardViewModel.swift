import Foundation
import Combine

@available(iOS 14.0, *)
class PhotoCardViewModel: ObservableObject {
    private let coverPhotoLoader: CoverPhotoLoader
    let coverPhoto: NodeEntity?
    let thumbnailUseCase: ThumbnailUseCaseProtocol
    @Published var coverPhotoURL: URL?
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
        self.coverPhotoLoader = CoverPhotoLoader(coverPhoto: coverPhoto, thumbnailUseCase: thumbnailUseCase)
        
        loadCoverPhoto()
    }
    
    func loadCoverPhoto() {
        coverPhotoLoader
            .loadCoverPhoto()
            .receive(on: DispatchQueue.main)
            .assign(to: &$coverPhotoURL)
    }
}
