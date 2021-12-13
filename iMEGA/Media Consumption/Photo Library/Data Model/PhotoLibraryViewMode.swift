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
