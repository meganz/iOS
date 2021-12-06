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
                return "Years"
            case .month:
                return "Months"
            case .day:
                return "Days"
            case .all:
                return "All"
            }
        }
    }
    
    @Published var library: PhotoLibrary
    
    init(library: PhotoLibrary) {
        self.library = library
    }
}
