import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import Search

extension SearchConfig {
    static var leftOffItems: SearchConfig {
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.continueWhereYouLeftIcon,
            title: Strings.Localizable.ContinueWhereYouLeftOff.Empty.message,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
        return .init(emptyViewAssetFactory: { _, _ in emptyViewAssets }, isContextMenuEnabled: false)
    }
}

extension SortHeaderConfig {
    static var leftOffItems: SortHeaderConfig {
        SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: [
                SortOption(key: .name, localizedTitle: Strings.Localizable.Sorting.Name.title),
                SortOption(key: .dateAdded, localizedTitle: Strings.Localizable.Sorting.LastAccessed.title)
            ]
        )
    }
}
