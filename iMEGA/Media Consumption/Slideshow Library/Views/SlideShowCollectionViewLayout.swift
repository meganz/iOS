import UIKit

final class SlideShowCollectionViewLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }
        let rectAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)

        for attributes in rectAttributes where attributes.frame.intersects(visibleRect) {
            let positionInFrameX = attributes.center.x - visibleRect.origin.x
            let cutoff = CGFloat(40)
            
            if positionInFrameX <= cutoff {
                let translation = cutoff - positionInFrameX
                let alpha = 1 - (translation / 100)
                attributes.alpha = alpha
            } else {
                attributes.zIndex = 1
            }
        }

        return rectAttributes
    }

    override init() { super.init() }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
}

