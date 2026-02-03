import MEGAAssets
import UIKit

// MARK: - Toolbar Actions

enum MediaBottomToolbarAction: Equatable {
    case shareLink
    case removeLink
    case delete
    case download
    case manageLink
    case saveToPhotos
    case sendToChat
    case more
    case moveToRubbishBin
    case addToAlbum

    var image: UIImage {
        switch self {
        case .shareLink:
            MEGAAssets.UIImage.link01
        case .removeLink:
            MEGAAssets.UIImage.removeLink
        case .delete, .moveToRubbishBin:
            MEGAAssets.UIImage.rubbishBinRevamp
        case .download:
            MEGAAssets.UIImage.offlineRevamp
        case .manageLink:
            MEGAAssets.UIImage.link01
        case .saveToPhotos:
            MEGAAssets.UIImage.saveToPhotosRevamp
        case .sendToChat:
            MEGAAssets.UIImage.sendToChatRevamp
        case .more:
            MEGAAssets.UIImage.moreList
        case .addToAlbum:
            MEGAAssets.UIImage.addToRevamp
        }
    }
}

// MARK: - Toolbar Configuration

struct MediaBottomToolbarConfig: Equatable {
    let actions: [MediaBottomToolbarAction]
    let selectedItemsCount: Int
    let isAllExported: Bool

    var hasSelection: Bool {
        selectedItemsCount > 0
    }
    
    init(
        actions: [MediaBottomToolbarAction],
        selectedItemsCount: Int,
        isAllExported: Bool = false
    ) {
        self.actions = actions
        self.selectedItemsCount = selectedItemsCount
        self.isAllExported = isAllExported
    }
}
