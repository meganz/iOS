import Foundation

final class PhotoLibraryAllViewModel: PhotoLibraryModeViewModel {
    @Published var library: PhotoLibrary
    @Published var monthSections: [PhotoMonthSection]
    var libraryViewModel: PhotoLibraryContentViewModel
    
    var currentScrollPositionId: PhotoPositionId {
        if let date = libraryViewModel.currentScrollPositionId {
            return date
        } else {
            return library.allPhotos.last?.categoryDate
        }
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
        self.library = libraryViewModel.library
        
        monthSections = libraryViewModel.library.allPhotosByMonthList.map {
            let title: String
            if #available(iOS 15.0, *) {
                title = $0.categoryDate.formatted(.dateTime.year().locale(.current))
            } else {
                title = DateFormatter.monthTemplate().localisedString(from: $0.categoryDate)
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
        var attr = photosByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let semibold = AttributeContainer.font(.subheadline.weight(.semibold))
        attr.replaceAttributes(month, with: semibold)
        
        return attr
    }
}
