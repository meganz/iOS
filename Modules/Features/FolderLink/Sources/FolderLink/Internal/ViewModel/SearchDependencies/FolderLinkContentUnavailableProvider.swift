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
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            subtitle: nil,
            font: .body,
            titleTextColor: TokenColors.Text.primary.swiftUI,
            actions: []
        )
    }
}
