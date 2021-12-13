import Foundation

@available(iOS 14.0, *)
final class PhotoMonthCardViewModel: PhotoCardViewModel {
    private let photosByMonth: PhotosByMonth
    
    let title: String
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photosByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(month, with: bold)
        
        return attr
    }

    init(photosByMonth: PhotosByMonth,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photosByMonth = photosByMonth
        
        if #available(iOS 15.0, *) {
            title = photosByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide))
        } else {
            title = DateFormatter.monthTemplate().localisedString(from: photosByMonth.categoryDate)
        }
        
        super.init(coverPhoto: photosByMonth.coverPhoto, thumbnailUseCase: thumbnailUseCase)
    }
}
