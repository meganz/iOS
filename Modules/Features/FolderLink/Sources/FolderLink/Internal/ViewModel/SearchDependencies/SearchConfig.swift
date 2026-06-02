import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    /// Folder Link currently only cares about empty assets.
    /// The rest of config are either not supported or same as CloudDrive, so they are copied over from CloudDriveViewControllerFactory
    static var folderLink: SearchConfig {
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )

        return .init(emptyViewAssetFactory: { _, _ in emptyViewAssets })
    }
}
