import Foundation

final class PhotoDaySection: PhotoDateSection {
    var photoByDay: PhotoByDay
    
    override var allPhotos: [NodeEntity] {
        photoByDay.photoNodeList
    }
    
    override var categoryDate: Date {
        photoByDay.categoryDate
    }
    
    override var coverPhoto: NodeEntity? {
        photoByDay.coverPhoto
    }
    
    override var photoByDayList: [PhotoByDay] {
        [photoByDay]
    }
    
    init(photoByDay: PhotoByDay) {
        self.photoByDay = photoByDay
        
        super.init()
        
        if #available(iOS 15.0, *) {
            title = photoByDay.categoryDate.formatted(.dateTime.year().locale(.current))
        } else {
            if photoByDay.categoryDate.isThisYear {
                title = DateFormatter.fromTemplate("MMMMd").localisedString(from: photoByDay.categoryDate)
            } else {
                title = DateFormatter.fromTemplate("MMMMdyyyy").localisedString(from: photoByDay.categoryDate)
            }
        }
    }
    
    @available(iOS 15.0, *)
    override var attributedTitle: AttributedString {
        var attr: AttributedString
        
        if photoByDay.categoryDate.isThisYear {
            attr = photoByDay.categoryDate.formatted(.dateTime.locale(.current).day().month(.wide).attributed)
        } else {
            attr = photoByDay.categoryDate.formatted(.dateTime.locale(.current).year().day().month(.wide).attributed)
        }
        
        return attr
    }
}

extension PhotoDaySection: Equatable {
    static func == (lhs: PhotoDaySection, rhs: PhotoDaySection) -> Bool {
        lhs.photoByDay == rhs.photoByDay
    }
}

extension PhotoLibrary {
    var allPhotosDaySections: [PhotoDaySection] {
        allPhotosByDayList.map { PhotoDaySection(photoByDay: $0)}
    }
}
