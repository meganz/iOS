import Foundation

public struct ContextAction: Hashable {
    let id = UUID()
    let type: ContextAction.Category
    let title: String
    let subtitle: String?
    var dynamicSubtitle: (() -> String)?
    let icon: String
    let subActions: [ContextAction]?
    
    public enum Category {
        case cameraUploads
        case info
        case rename
        case showInCloudDrive
        case showInBackups
        case sort
        case sortAscending
        case sortDescending
        case sortLargest
        case sortSmallest
        case sortNewest
        case sortOldest
        case sortLabel
        case sortFavourite
    }

    public init(type: ContextAction.Category, title: String, subtitle: String? = nil, dynamicSubtitle: (() -> String)? = nil, icon: String, subActions: [ContextAction]? = nil) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.dynamicSubtitle = dynamicSubtitle
        self.icon = icon
        self.subActions = subActions
    }
    
    public static func == (lhs: ContextAction, rhs: ContextAction) -> Bool {
        lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
