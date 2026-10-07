import UIKit

/// What a measured height depends on. A height measured under another key is a guess again.
package struct MarkdownRowSizingKey: Equatable, Sendable {
    package var width: CGFloat = 0
    package var contentSizeCategory: UIContentSizeCategory = .unspecified
    package var legibilityWeight: UILegibilityWeight = .unspecified
    /// Grows on every theme change. A cell cannot compare themes itself.
    package var themeVersion = 0

    /// True when a cell with `traits`, sized at `width`, would give the height measured under this key.
    package func matches(traits: UITraitCollection, width: CGFloat) -> Bool {
        self.width == width
            && contentSizeCategory == traits.preferredContentSizeCategory
            && legibilityWeight == traits.legibilityWeight
    }
}

/// Layout attributes that tell the cell whether its height is already measured.
package final class MarkdownRowLayoutAttributes: UICollectionViewLayoutAttributes {
    // `isEqual` is not isolated, but UIKit copies and compares attributes on the main thread only.
    /// True when the cell sized itself under `sizingKey` and needs no new sizing.
    nonisolated(unsafe) package var isMeasured = false
    nonisolated(unsafe) package var sizingKey = MarkdownRowSizingKey()

    override package func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        guard let attributes = copy as? MarkdownRowLayoutAttributes else { return copy }
        attributes.isMeasured = isMeasured
        attributes.sizingKey = sizingKey
        return attributes
    }

    override package func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MarkdownRowLayoutAttributes else { return false }
        return other.isMeasured == isMeasured && other.sizingKey == sizingKey && super.isEqual(object)
    }
}
