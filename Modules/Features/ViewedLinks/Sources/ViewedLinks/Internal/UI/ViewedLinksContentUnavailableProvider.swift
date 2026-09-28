import MEGASwiftUI
import Search

/// Required by the search results view model, which has no default provider.
struct ViewedLinksContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: Search.SearchQuery,
        appliedChips: [Search.SearchChipEntity],
        config: Search.SearchConfig
    ) -> ContentUnavailableViewModel {
        config.emptyViewAssetFactory(nil, query).emptyViewModel
    }
}
