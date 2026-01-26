import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search

struct FolderLinkContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: Search.SearchQuery,
        appliedChips: [Search.SearchChipEntity],
        config: Search.SearchConfig
    ) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: query.isSearchActive ? MEGAAssets.Image.glassSearch02 : MEGAAssets.Image.glassFolder,
            title: query.isSearchActive ? Strings.Localizable.noResults : Strings.Localizable.emptyFolder,
            subtitle: nil,
            font: .body,
            titleTextColor: TokenColors.Text.primary.swiftUI,
            actions: []
        )
    }
}
