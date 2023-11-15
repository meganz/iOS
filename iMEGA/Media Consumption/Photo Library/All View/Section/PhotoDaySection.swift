import Foundation

final class PhotoDaySection: PhotoDateSection {
    init(photoByDay: PhotoByDay) {
        let title: String
        if photoByDay.categoryDate.isThisYear {
            title = DateFormatter.fromTemplate("MMMMd").localisedString(from: photoByDay.categoryDate)
        } else {
            title = DateFormatter.fromTemplate("MMMMdyyyy").localisedString(from: photoByDay.categoryDate)
        }
        
        super.init(contentList: photoByDay.contentList,
                   photoByDayList: [photoByDay],
                   categoryDate: photoByDay.categoryDate,
                   title: title)
    }
    
    override var attributedTitle: AttributedString {
        var attr: AttributedString
        let bold = AttributeContainer.font(.body.bold())
        
        if categoryDate.isThisYear {
            attr = categoryDate.formatted(.dateTime.locale(.current).day().month(.wide).attributed)
        } else {
            attr = categoryDate.formatted(.dateTime.locale(.current).year().day().month(.wide).attributed)
        }
        
        attr.replaceAttributes(AttributeContainer.dateField(.month), with: bold)
        attr.replaceAttributes(AttributeContainer.dateField(.day), with: bold)
        
        return attr
    }
}

extension PhotoLibrary {
    var photoDaySections: [PhotoDaySection] {
        photosByDayList.map { PhotoDaySection(photoByDay: $0)}
    }
}
