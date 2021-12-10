import Foundation

final class PhotoLibraryContentViewModel: ObservableObject {
    enum ViewMode: CaseIterable, Identifiable {
        case year
        case month
        case day
        case all
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .year:
                return Strings.Localizable.CameraUploads.Years.title
            case .month:
                return Strings.Localizable.months.localizedCapitalized
            case .day:
                return Strings.Localizable.days.localizedCapitalized
            case .all:
                return Strings.Localizable.all
            }
        }
    }
    
    @Published var library: PhotoLibrary
    
    init(library: PhotoLibrary) {
        self.library = library
    }
}
