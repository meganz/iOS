import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct MediaNavigationBarItemFactory {
    // MARK: - Leading Navigation Bar Items

    /// Creates a camera upload status button navigation bar item
    /// - Parameters:
    ///   - id: Unique identifier for this navigation bar item
    ///   - viewModel: The camera upload status button view model
    ///   - action: Action to perform when the button is tapped
    /// - Returns: A navigation bar item view model for the camera upload status button
    static func cameraUploadStatusButton(
        id: String = "cameraUploadStatus",
        viewModel: CameraUploadStatusButtonViewModel,
        action: @escaping () -> Void
    ) -> NavigationBarItemViewModel {
        NavigationBarItemViewModel(
            id: id,
            placement: .leading,
            type: .cameraUploadStatus(viewModel: viewModel, action: action)
        )
    }

    /// Creates a select all button navigation bar item
    /// - Parameters:
    ///   - id: Unique identifier for this navigation bar item
    ///   - action: Action to perform when the button is tapped
    /// - Returns: A navigation bar item view model for the select all button
    static func selectAllButton(
        id: String = "selectAll",
        action: @escaping () -> Void
    ) -> NavigationBarItemViewModel {
        NavigationBarItemViewModel(
            id: id,
            placement: .leading,
            type: .imageButton(image: MEGAAssets.UIImage.selectAllItems, action: action)
        )
    }

    // MARK: - Trailing Navigation Bar Items

    /// Creates a search button navigation bar item
    /// - Parameters:
    ///   - id: Unique identifier for this navigation bar item
    ///   - action: Action to perform when the button is tapped
    /// - Returns: A navigation bar item view model for the search button
    static func searchButton(
        id: String = "search",
        action: @escaping () -> Void
    ) -> NavigationBarItemViewModel {
        NavigationBarItemViewModel(
            id: id,
            placement: .trailing,
            type: .imageButton(image: MEGAAssets.UIImage.search, action: action)
        )
    }

    /// Creates a context menu button navigation bar item
    /// - Parameters:
    ///   - id: Unique identifier for this navigation bar item
    ///   - config: The context menu configuration
    ///   - manager: The context menu manager
    /// - Returns: A navigation bar item view model for the context menu button
    static func contextMenuButton(
        id: String = "contextMenu",
        config: CMConfigEntity,
        manager: ContextMenuManager
    ) -> NavigationBarItemViewModel {
        NavigationBarItemViewModel(
            id: id,
            placement: .trailing,
            type: .contextMenu(config: config, manager: manager)
        )
    }

    /// Creates a cancel button navigation bar item
    /// - Parameters:
    ///   - id: Unique identifier for this navigation bar item
    ///   - action: Action to perform when the button is tapped
    /// - Returns: A navigation bar item view model for the cancel button
    static func cancelButton(
        id: String = "cancel",
        action: @escaping () -> Void
    ) -> NavigationBarItemViewModel {
        NavigationBarItemViewModel(
            id: id,
            placement: .trailing,
            type: .textButton(text: Strings.Localizable.cancel, action: action)
        )
    }
}
