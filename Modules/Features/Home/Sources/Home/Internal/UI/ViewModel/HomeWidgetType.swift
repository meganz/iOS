import Foundation

/// Defines all available widget types
enum HomeWidgetType: CaseIterable, Identifiable {
    var id: Self { self }
    case shortcuts
    case accountDetails
    case promotionalBanners
}
