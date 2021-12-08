import Foundation

final class PhotoDayCardViewModel: ObservableObject {
    private let photosByDay: PhotosByDay
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    let title: String
    
    @Published var coverPhotoURL: URL?
    
    var badgeTitle: String? {
        return photosByDay.photoNodeList.count > 1 ? "+\(photosByDay.photoNodeList.count)": nil
    }
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photosByDay.day.formatted(.dateTime.locale(.current).year().month(.wide).day().attributed)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(AttributeContainer.dateField(.month), with: bold)
        attr.replaceAttributes(AttributeContainer.dateField(.day), with: bold)
        
        return attr
    }
    
    init(photosByDay: PhotosByDay,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photosByDay = photosByDay
        self.thumbnailUseCase = thumbnailUseCase
        
        if #available(iOS 15.0, *) {
            title = photosByDay.day.formatted(.dateTime.locale(.current).year().month(.wide).day())
        } else {
            title = DateFormatter.dateLong().localisedString(from: photosByDay.day)
        }
        
        loadCoverPhoto()
    }
    
    func loadCoverPhoto() {
        guard let coverPhoto = photosByDay.coverPhoto else { return }
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
