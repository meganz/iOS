import UIKit

/// A list cell whose content view comes from the data source (`contentConfiguration`).
/// It sizes itself to the content height at the layout width, and skips that work when its height is already measured.
package final class MarkdownRowCell: UICollectionViewCell {
    override package func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let width = layoutAttributes.size.width
        if let attributes = layoutAttributes as? MarkdownRowLayoutAttributes,
           attributes.isMeasured,
           attributes.sizingKey.matches(traits: traitCollection, width: width) {
            return layoutAttributes
        }
        let fitted = contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        guard let result = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else { return layoutAttributes }
        result.size = CGSize(width: width, height: max(ceil(fitted.height), 1))
        // UIKit tells the layout only about attributes that differ. With this flag a size equal to the estimate
        // still reaches the layout, which then marks the item measured.
        (result as? MarkdownRowLayoutAttributes)?.isMeasured = true
        return result
    }
}
