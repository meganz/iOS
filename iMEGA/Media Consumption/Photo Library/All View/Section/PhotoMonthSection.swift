import Foundation

final class PhotoMonthSection: PhotoDateSection {
    init(photoByMonth: PhotoByMonth) {
        super.init(contentList: photoByMonth.allPhotos,
                   photoByDayList: photoByMonth.contentList,
                   categoryDate: photoByMonth.categoryDate,
                   title: DateFormatter.monthTemplate().localisedString(from: photoByMonth.categoryDate))
    }
    
    override var attributedTitle: AttributedString {
        var attr = categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let semibold = AttributeContainer.font(.subheadline.weight(.semibold))
        attr.replaceAttributes(month, with: semibold)
        
        return attr
    }
}

extension PhotoLibrary {
    var photoMonthSections: [PhotoMonthSection] {
        photosByMonthList.map { PhotoMonthSection(photoByMonth: $0) }
    }
}
