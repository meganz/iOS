import Foundation

final class PhotoYearCardViewModel: ObservableObject {
    private let photosByYear: PhotosByYear
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    let title: String
    
    @Published var coverPhotoURL: URL?
    
    init(photosByYear: PhotosByYear,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photosByYear = photosByYear
        self.thumbnailUseCase = thumbnailUseCase
        
        if #available(iOS 15.0, *) {
            title = photosByYear.year.formatted(.dateTime.year().locale(.current))
        } else {
            title = DateFormatter.yearTemplate().localisedString(from: photosByYear.year)
        }
        
        loadCoverPhoto()
    }
    
    func loadCoverPhoto() {
        guard let coverPhoto = photosByYear.coverPhoto else { return }
        thumbnailUseCase.getCachedPreview(for: coverPhoto.handle) { [weak self] result in
            switch result {
            case .failure:
                break
            case .success(let url):
                self?.coverPhotoURL = url
            }
        }
    }
}
