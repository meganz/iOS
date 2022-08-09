import Foundation

struct EmptyStateConfiguration {

    let emptyStateView: () -> UIView
}

extension EmptyStateConfiguration {

    static var searchHints: Self {
        Self.init {
            EmptyStateView(
                image: Asset.Images.EmptyStates.searchEmptyState.image,
                title: Strings.Localizable.noResults,
                description: nil,
                buttonTitle: nil
            )
        }
    }

    static var searchResult: Self {
        Self.init {
            EmptyStateView(
                image: Asset.Images.EmptyStates.searchEmptyState.image,
                title: Strings.Localizable.noResults,
                description: nil,
                buttonTitle: nil
            )
        }
    }
}
