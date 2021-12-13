import Foundation

@available(iOS 14.0, *)
final class PhotoDayCardViewModel: PhotoCardViewModel {
    private let photosByDay: PhotosByDay
    
    let title: String
    
    var badgeTitle: String? {
        return photosByDay.photoNodeList.count > 1 ? "+\(photosByDay.photoNodeList.count)": nil
    }
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photosByDay.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).day().attributed)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(AttributeContainer.dateField(.month), with: bold)
        attr.replaceAttributes(AttributeContainer.dateField(.day), with: bold)
        
        return attr
    }
    
    init(photosByDay: PhotosByDay,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photosByDay = photosByDay
        
        if #available(iOS 15.0, *) {
            title = photosByDay.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).day())
        } else {
            title = DateFormatter.dateLong().localisedString(from: photosByDay.categoryDate)
        }
        
        super.init(coverPhoto: photosByDay.coverPhoto, thumbnailUseCase: thumbnailUseCase)
    }
}
