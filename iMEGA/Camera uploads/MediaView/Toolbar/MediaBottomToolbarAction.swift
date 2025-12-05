import MEGAAssets
import UIKit

// MARK: - Toolbar Actions

enum MediaBottomToolbarAction {
    case shareLink
    case removeLink
    case delete

    var image: UIImage {
        switch self {
        case .shareLink:
            MEGAAssets.UIImage.link
        case .removeLink:
            MEGAAssets.UIImage.removeLink
        case .delete:
            MEGAAssets.UIImage.rubbishBin
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
