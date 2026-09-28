import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import Search

extension SearchConfig {
    static var viewedLinks: SearchConfig {
        // Empty view is no-op in Viewed Link screen: The screen closes as soon as its last link
        // is removed so `emptyViewAssets` is just a placeholder to satisfy SearchConfig here.
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.viewedLinks,
            title: Strings.Localizable.ViewedLinks.Empty.message,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
        return .init(emptyViewAssetFactory: { _, _ in emptyViewAssets }, isContextMenuEnabled: false)
    }
}

extension SortHeaderConfig {
    static var viewedLinks: SortHeaderConfig {
        SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: [
                SortOption(key: .name, localizedTitle: Strings.Localizable.Sorting.Name.title),
                SortOption(key: .dateAdded, localizedTitle: Strings.Localizable.Sorting.LastAccessed.title)
            ]
        )
    }
}
