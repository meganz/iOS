import Foundation

final class PhotoLibraryAllViewModel: ObservableObject {
    @Published var library: PhotoLibrary
    @Published var monthSections: [PhotoMonthSection]
    
    init(library: PhotoLibrary) {
        self.library = library
        
        monthSections = library.allPhotosByMonthList.map {
            let title: String
            if #available(iOS 15.0, *) {
                title = $0.month.formatted(.dateTime.year().locale(.current))
            } else {
                title = DateFormatter.yearTemplate().localisedString(from: $0.month)
            }
            
            return PhotoMonthSection(photosByMonth: $0, title: title)
        }
    }
}

struct PhotoMonthSection: Identifiable {
    var photosByMonth: PhotosByMonth
    var title: String
    let id = UUID()
    
    @available(iOS 15.0, *)
    var attributedTitle: AttributedString {
        var attr = photosByMonth.month.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let semibold = AttributeContainer.font(.subheadline.weight(.semibold))
        attr.replaceAttributes(month, with: semibold)
        
        return attr
    }
}
