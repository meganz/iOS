import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search

struct FavouritesContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: Search.SearchQuery,
        appliedChips: [Search.SearchChipEntity],
        config: Search.SearchConfig
    ) -> ContentUnavailableViewModel {
        .init(
            image: MEGAAssets.Image.favouritesEmptyState,
            title: Strings.Localizable.noFavourites,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
}
