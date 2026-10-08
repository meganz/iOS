import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search

struct LeftOffItemsContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: Search.SearchQuery,
        appliedChips: [Search.SearchChipEntity],
        config: Search.SearchConfig
    ) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel.noLeftOffItems
    }
}

fileprivate extension ContentUnavailableViewModel {
    static var noLeftOffItems: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.continueWhereYouLeftIcon,
            title: Strings.Localizable.ContinueWhereYouLeftOff.Empty.message,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
}
