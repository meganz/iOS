import Foundation

struct ContextAction {
    let id = UUID()
    let type: ContextAction.Category
    let icon: String
    let title: String
    
    enum Category {
        case rename
        case shareLink
        case manageLink
        case removeLink
        case deletePlaylist
    }
}
