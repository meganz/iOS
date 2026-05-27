import Foundation

enum HomeWidgetType: String, CaseIterable, Identifiable, Codable {
    var id: Self { self }
    case shortcuts
    case recents
    case accountDetails
    case promotionalBanners
    case viewedLinks
    case continueWhereYouLeft
    case doMoreWithMega

    /// The fixed widget list for Home Revamp Phase 1
    static var phase1Widgets: [HomeWidgetType] {
        [.shortcuts, .accountDetails, .promotionalBanners, .recents]
    }
}
