import Foundation

final class PhotoDaySection: PhotoDateSection {
    init(photoByDay: PhotoByDay) {
        super.init(contentList: photoByDay.contentList)
        
        photoByDayList = [photoByDay]
        categoryDate = photoByDay.categoryDate
        
        if #available(iOS 15.0, *) {
            title = categoryDate.formatted(.dateTime.year().locale(.current))
        } else {
            if categoryDate.isThisYear {
                title = DateFormatter.fromTemplate("MMMMd").localisedString(from: photoByDay.categoryDate)
            } else {
                title = DateFormatter.fromTemplate("MMMMdyyyy").localisedString(from: photoByDay.categoryDate)
            }
        }
    }
    
    @available(iOS 15.0, *)
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
    var allPhotosDaySections: [PhotoDaySection] {
        allPhotosByDayList.map { PhotoDaySection(photoByDay: $0)}
    }
}
