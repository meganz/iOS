import MEGAAssets
import UIKit

// MARK: - Toolbar Actions

enum MediaBottomToolbarAction {
    case shareLink
    case removeLink
    case delete
    // Video-specific actions
    case download
    case manageLink
    case saveToPhotos
    case sendToChat
    case more

    var image: UIImage {
        switch self {
        case .shareLink:
            MEGAAssets.UIImage.link
        case .removeLink:
            MEGAAssets.UIImage.removeLink
        case .delete:
            MEGAAssets.UIImage.rubbishBin
        case .download:
            MEGAAssets.UIImage.offline
        case .manageLink:
            MEGAAssets.UIImage.link
        case .saveToPhotos:
            MEGAAssets.UIImage.saveToPhotos
        case .sendToChat:
            MEGAAssets.UIImage.sendToChat
        case .more:
            MEGAAssets.UIImage.moreList
        }
    }
}

// MARK: - Toolbar Configuration

struct MediaBottomToolbarConfig: Equatable {
    let actions: [MediaBottomToolbarAction]
    let selectedItemsCount: Int
    let hasExportedItems: Bool
    let isAllExported: Bool

    var hasSelection: Bool {
        selectedItemsCount > 0
    }
}
