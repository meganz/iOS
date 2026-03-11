import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search

// [IOS-11392]: Refine search empty state
struct HomeScreenContentUnavailableViewModelProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassSearch02,
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            font: .body,    
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
}
