import MEGAAssets
import MEGAL10n
import SwiftUI

/// These actions are mapped to FolderLinkNodesAction and are passed back to external dependency to handle them
/// There is also Share Link quick action but not added here,
/// because it is handled natively using [ShareLink](https://developer.apple.com/documentation/SwiftUI/ShareLink) SwiftUI view
/// Check the ShareLinkButton usage in FolderLinkResultsView
enum FolderLinkQuickAction {
    case addToCloudDrive
    case makeAvailableOffline
    case sendToChat
}

/// These actions are mapped to FolderLinkNodesAction and are passed back to external dependency to handle them
/// There is also Share Link quick action but not added here,
/// because it is handled natively using [ShareLink](https://developer.apple.com/documentation/SwiftUI/ShareLink) SwiftUI view
/// Check the ShareLinkButton usage in FolderLinkResultsView
enum FolderLinkBottomBarAction {
    case addToCloudDrive
    case makeAvailableOffline
    case saveToPhotos
}
