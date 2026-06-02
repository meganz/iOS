import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import Search

extension SearchConfig {
    static var recentAction: SearchConfig {
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )

        return .init(emptyViewAssetFactory: { _, _ in emptyViewAssets })
    }
}

extension SortHeaderConfig {
    // Recent does not support sort header
    static var recentAction: SortHeaderConfig {
        return SortHeaderConfig(
            title: "",
            options: []
        )
    }
}
