import MEGASwiftUI
@MainActor
public protocol ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel
}
