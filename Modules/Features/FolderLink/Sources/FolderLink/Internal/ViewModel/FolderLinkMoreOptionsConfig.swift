import SwiftUI

/// The rows the revamped more options sheet offers and the state each of them is in.
///
/// Built the same way for the list/grid and the gallery screens, so the two offer the same actions and a
/// row added here shows up on both.
struct FolderLinkMoreOptionsConfig {
    let options: [FolderLinkMoreOption]
    let disabledOptions: Set<FolderLinkMoreOption>

    /// The sheet took over Share link from the bottom bar, where it stayed enabled for a folder with no
    /// children, so the button that opens it cannot be gated on Select alone any more — it is disabled
    /// only once every row the sheet holds is.
    let isMoreOptionsButtonDisabled: Bool

    /// - Parameters:
    ///   - canSelect: whether the folder holds anything to select.
    ///   - showsQuickActions: whether the folder-wide actions apply, which they do not for a folder whose
    ///     key is still undecrypted.
    ///   - includesDownload: whether every node the action would cover can be saved to Photos.
    ///   - isNetworkConnected: every row needs the network, so losing it disables the button outright.
    init(
        canSelect: Bool,
        showsQuickActions: Bool,
        includesDownload: Bool,
        isNetworkConnected: Bool
    ) {
        var options: [FolderLinkMoreOption] = [.select]
        if showsQuickActions {
            options.append(.saveToMEGA)
            // Save to Photos lost its bottom bar slot to the two anchored buttons, so the sheet is where
            // it lives now, labelled Download as the design asks.
            if includesDownload {
                options.append(.download)
            }
            options.append(contentsOf: [.copyToOffline, .shareLink, .sendToChat])
        }

        self.options = options
        // Selecting needs something to select; the other rows of the sheet do not.
        disabledOptions = canSelect ? [] : [.select]
        isMoreOptionsButtonDisabled = !isNetworkConnected || (!canSelect && !showsQuickActions)
    }
}

/// The view model surface the revamped more options sheet drives. Both the list/grid and the gallery view
/// models expose it, so the row-to-action mapping lives here rather than being repeated in each view.
@MainActor
protocol FolderLinkMoreOptionsHandling: AnyObject {
    var editMode: EditMode { get set }
    var quickAction: FolderLinkQuickAction? { get set }
    var bottomBarAction: FolderLinkBottomBarAction? { get set }
}

extension FolderLinkMoreOptionsHandling {
    func handle(moreOption: FolderLinkMoreOption) {
        switch moreOption {
        case .select:
            editMode = .active
        case .saveToMEGA:
            quickAction = .addToCloudDrive
        case .copyToOffline:
            quickAction = .makeAvailableOffline
        case .sendToChat:
            quickAction = .sendToChat
        case .download:
            bottomBarAction = .saveToPhotos
        case .shareLink:
            // Handled by the ShareLink the sheet renders for this row.
            break
        }
    }
}
