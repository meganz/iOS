import UIKit

/// An animator that applies cross fade effect to the cells when you scroll.
/// The current cell will fade out and the next one will fade in.
public struct CrossFadeAttributesAnimator: LayoutAttributesAnimator {
    public init() {}

    public func animate(collectionView: UICollectionView, attributes: AnimatedCollectionViewLayoutAttributes) {
        let position = attributes.middleOffset
        let contentOffset = collectionView.contentOffset
        attributes.frame = CGRect(origin: contentOffset, size: attributes.frame.size)
        attributes.alpha = 1 - abs(position)
    }
}
