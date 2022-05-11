import Foundation

enum PhotoLibraryViewMode: CaseIterable, Identifiable {
    case year
    case month
    case day
    case all
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .year:
            return Strings.Localizable.Media.PhotoLibrary.Category.Years.title
        case .month:
            return Strings.Localizable.Media.PhotoLibrary.Category.Months.title
        case .day:
            return Strings.Localizable.Media.PhotoLibrary.Category.Days.title
        case .all:
            return Strings.Localizable.Media.PhotoLibrary.Category.All.title
        }
    }
}
