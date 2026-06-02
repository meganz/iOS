import Foundation

package enum HomeWidgetType: String, CaseIterable, Identifiable, Codable {
    package var id: Self { self }
    case shortcuts
    case accountDetails
    case promotionalBanners
    case recents
    case viewedLinks
    case continueWhereYouLeft
    case doMoreWithMega

    /// The fixed widget list for Home Revamp Phase 1
    static var phase1Widgets: [HomeWidgetType] {
        [.shortcuts, .accountDetails, .promotionalBanners, .recents]
    }
}
