import UIKit

/// The collection view of a row list. Layout passes never animate, and text size changes are reported.
/// It never sets `contentInset` or the scroll indicator insets: the host owns them, for example for the keyboard.
package final class MarkdownRowListView: UICollectionView {
    /// Called after each layout pass.
    package var onLayout: (() -> Void)?
    /// Called when the text size or Bold Text changes. Both change the fonts, so every height is a guess again.
    package var onTextSizeChange: (() -> Void)?

    override package init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLegibilityWeight.self]) { (view: Self, _) in
            view.onTextSizeChange?()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override package func layoutSubviews() {
        // Without this, UIKit animates cells that size themselves: rows slide in from far away while scrolling.
        UIView.performWithoutAnimation { super.layoutSubviews() }
        onLayout?()
    }
}
