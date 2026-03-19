import MEGASwiftUI
import Search

/// This is needed to inject to Search module as Search currently does not support optional.
/// But, RecentActionBucketItemsView does not need to support empty view. When the bucket become empty, we just pop to parent screen and show a snack bar message.
struct RecentActionBucketItemsContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(query: Search.SearchQuery, appliedChips: [Search.SearchChipEntity], config: Search.SearchConfig) -> ContentUnavailableViewModel {
        .noResults
    }
}
