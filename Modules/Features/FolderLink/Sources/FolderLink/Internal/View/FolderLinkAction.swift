import MEGAAssets
import MEGAL10n
import SwiftUI

/// These actions are mapped to FolderLinkNodesAction and are passed back to external dependency to handle them
/// There is also Share Link quick action but not added here,
/// because it is handled natively using [ShareLink](https://developer.apple.com/documentation/SwiftUI/ShareLink) SwiftUI view
/// Check the ShareLinkButton usage in FolderLinkResultsView
package enum FolderLinkQuickAction: Sendable {
    case addToCloudDrive
    case makeAvailableOffline
    case sendToChat
}

/// These actions are mapped to FolderLinkNodesAction and are passed back to external dependency to handle them
/// There is also Share Link quick action but not added here,
/// because it is handled natively using [ShareLink](https://developer.apple.com/documentation/SwiftUI/ShareLink) SwiftUI view
/// Check the ShareLinkButton usage in FolderLinkResultsView
package enum FolderLinkBottomBarAction: Sendable {
    case makeAvailableOffline
    /// Saves to the device rather than to the Offline section, through the system share sheet where
    /// Save to Files lives. Named apart from `makeAvailableOffline` so the two destinations do not read
    /// as the same thing — the button itself is labelled Download, as the design asks.
    case downloadToFiles
    case addToCloudDrive
    case saveToPhotos
}
