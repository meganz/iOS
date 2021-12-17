import Foundation

struct PhotosMonthSection: Identifiable {
    var photosByMonth: PhotosByMonth
    var title: String
    let id = UUID()
    
    init(photosByMonth: PhotosByMonth) {
        self.photosByMonth = photosByMonth
        
        if #available(iOS 15.0, *) {
            title = photosByMonth.categoryDate.formatted(.dateTime.year().locale(.current))
        } else {
            title = DateFormatter.monthTemplate().localisedString(from: photosByMonth.categoryDate)
        }
    }
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photosByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let semibold = AttributeContainer.font(.subheadline.weight(.semibold))
        attr.replaceAttributes(month, with: semibold)
        
        return attr
    }
}

extension PhotosMonthSection: PhotosChronologicalCategory {
    var categoryDate: Date {
        photosByMonth.allPhotos.last?.categoryDate ?? Date()
    }
    
    var coverPhoto: NodeEntity? {
        photosByMonth.allPhotos.last
    }
}

extension PhotoLibrary {
    var allPhotosMonthSections: [PhotosMonthSection] {
        allPhotosByMonthList.map { PhotosMonthSection(photosByMonth: $0) }
    }
}
