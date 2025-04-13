import Foundation
import UIKit

/// A `UICollectionViewFlowLayout` subclass enables custom transitions between cells.
class AnimatedCollectionViewLayout: UICollectionViewFlowLayout {

    /// The animator that would actually handle the transitions.
    open var animator: (any LayoutAttributesAnimator)?

    // open Overrided so that we can store extra information in the layout attributes.
    public override class var layoutAttributesClass: AnyClass { return AnimatedCollectionViewLayoutAttributes.self }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        return attributes.compactMap { $0.copy() as? AnimatedCollectionViewLayoutAttributes }.map { self.transformLayoutAttributes($0) }
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // We have to return true here so that the layout attributes would be recalculated
        // every time we scroll the collection view.
        return true
    }

    private func transformLayoutAttributes(_ attributes: AnimatedCollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

        guard let collectionView = self.collectionView else { return attributes }

        /**
         The position for each cell is defined as the ratio of the distance between
         the center of the cell and the center of the collectionView and the collectionView width/height
         depending on the scroll direction. It can be negative if the cell is, for instance,
         on the left of the screen if you're scrolling horizontally.
         */

        let distance: CGFloat
        let itemOffset: CGFloat

        if scrollDirection == .horizontal {
            distance = collectionView.frame.width
            itemOffset = attributes.center.x - collectionView.contentOffset.x
            attributes.startOffset = (attributes.frame.origin.x - collectionView.contentOffset.x) / attributes.frame.width
            attributes.endOffset = (attributes.frame.origin.x - collectionView.contentOffset.x - collectionView.frame.width) / attributes.frame.width
        } else {
            distance = collectionView.frame.height
            itemOffset = attributes.center.y - collectionView.contentOffset.y
            attributes.startOffset = (attributes.frame.origin.y - collectionView.contentOffset.y) / attributes.frame.height
            attributes.endOffset = (attributes.frame.origin.y - collectionView.contentOffset.y - collectionView.frame.height) / attributes.frame.height
        }

        attributes.scrollDirection = scrollDirection
        attributes.middleOffset = itemOffset / distance - 0.5

        // Cache the contentView since we're going to use it a lot.
        if attributes.contentView == nil,
            let cell = collectionView.cellForItem(at: attributes.indexPath)?.contentView {
            attributes.contentView = cell
        }

        animator?.animate(collectionView: collectionView, attributes: attributes)

        return attributes
    }
}

/// A custom layout attributes that contains extra information.
open class AnimatedCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    public var contentView: UIView?
    public var scrollDirection: UICollectionView.ScrollDirection = .vertical

    /// The ratio of the distance between the start of the cell and the start of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the start of the cell aligns the start of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
    public var startOffset: CGFloat = 0

    /// The ratio of the distance between the center of the cell and the centre of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the center of the cell aligns the center of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
    public var middleOffset: CGFloat = 0

    /// The ratio of the distance between the **start** of the cell and the end of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the **start** of the cell aligns the end of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
    public var endOffset: CGFloat = 0

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AnimatedCollectionViewLayoutAttributes
        copy.contentView = contentView
        copy.scrollDirection = scrollDirection
        copy.startOffset = startOffset
        copy.middleOffset = middleOffset
        copy.endOffset = endOffset
        return copy
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let o = object as? AnimatedCollectionViewLayoutAttributes else { return false }

        return o.contentView == contentView
            && o.scrollDirection == scrollDirection
            && o.startOffset == startOffset
            && o.middleOffset == middleOffset
            && o.endOffset == endOffset
    }
}
