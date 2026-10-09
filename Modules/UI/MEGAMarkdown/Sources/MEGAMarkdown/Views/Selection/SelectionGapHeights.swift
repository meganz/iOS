import UIKit

/// The gap heights below rows, for a highlight that leaves the gap out.
/// The estimator is made again only when the width, the text size, Bold Text or the theme change, not in every layout pass.
package struct SelectionGapHeights {
    private struct Key: Equatable {
        let width: CGFloat
        let contentSize: UIContentSizeCategory
        let legibility: UILegibilityWeight
        let theme: MarkdownTheme
    }

    private var cache: (key: Key, estimator: MarkdownRowEstimator)?

    package init() {}

    /// The estimator for the rows of `view` in `theme`.
    @MainActor
    package mutating func estimator(for view: UIView, theme: MarkdownTheme) -> MarkdownRowEstimator {
        let traits = view.traitCollection
        let key = Key(width: view.bounds.width, contentSize: traits.preferredContentSizeCategory,
                      legibility: traits.legibilityWeight, theme: theme)
        if let cache, cache.key == key { return cache.estimator }
        let estimator = MarkdownRowEstimator(width: key.width, traits: traits, theme: theme)
        cache = (key, estimator)
        return estimator
    }
}
