import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static var favourites: SearchConfig {
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )

        return .init(emptyViewAssetFactory: { _, _ in emptyViewAssets })
    }
}
