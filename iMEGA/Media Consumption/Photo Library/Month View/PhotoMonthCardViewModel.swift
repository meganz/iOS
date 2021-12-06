import Foundation

final class PhotoMonthCardViewModel: ObservableObject {
    private let photosByMonth: PhotosByMonth
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    let title: String
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photosByMonth.month.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(month, with: bold)
        
        return attr
    }
    
    @Published var coverPhotoURL: URL?
    
    init(photosByMonth: PhotosByMonth,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photosByMonth = photosByMonth
        self.thumbnailUseCase = thumbnailUseCase
        
        if #available(iOS 15.0, *) {
            title = photosByMonth.month.formatted(.dateTime.locale(.current).year().month(.wide))
        } else {
            title = DateFormatter.monthTemplate().localisedString(from: photosByMonth.month)
        }
        
        loadCoverPhoto()
    }
    
    func loadCoverPhoto() {
        guard let coverPhoto = photosByMonth.coverPhoto else { return }
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
