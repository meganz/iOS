import Foundation
import MEGAL10n

struct EmptyStateConfiguration {

    let emptyStateView: () -> UIView
}

extension EmptyStateConfiguration {

    static var searchHints: Self {
        Self.init {
            EmptyStateView(
                image: UIImage.searchEmptyState,
                title: Strings.Localizable.noResults,
                description: nil,
                buttonTitle: nil
            )
        }
    }

    static var searchResult: Self {
        Self.init {
            EmptyStateView(
                image: UIImage.searchEmptyState,
                title: Strings.Localizable.noResults,
                description: nil,
                buttonTitle: nil
            )
        }
    }
}
