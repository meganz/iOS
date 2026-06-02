import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static var homeSearchConfig: SearchConfig {
        .init(emptyViewAssetFactory: { _, _ in // This isn't used in Revamp UI, this is just here to satisfy the struct's initialization
            .init(
                image: MEGAAssets.Image.glassSearch02,
                title: Strings.Localizable.Home.Search.Empty.noChipSelected,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        })
    }
}
