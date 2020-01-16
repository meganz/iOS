
import UIKit

class PhotoCarousalFlowLayout: UICollectionViewFlowLayout {
    fileprivate var cellEstimatedCenterPoints: [CGPoint] = []
    fileprivate var cellEstimatedFrames: [CGRect] = []
    var cellSpacing: CGFloat = 100
    var shouldLayoutEverything = true

    var cellCount: Int {
        guard let collectionView = collectionView,
            let dataSource = collectionView.dataSource else {
            return 0
        }
        
       return dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
    }
    
    var collectionViewWidth: CGFloat {
         guard let collectionView = collectionView else {
             return 0
         }
        
        return collectionView.bounds.width
    }
    
    var collectionViewHeight: CGFloat {
         guard let collectionView = collectionView else {
             return 0
         }
        
        return collectionView.bounds.height
    }
    
    var currentPage: Int = 0

    override func prepare() {
        guard shouldLayoutEverything else { return }
        
        if let collectionView = collectionView {
            let collectionViewXOffset = ceil(CGFloat(currentPage) * collectionViewWidth)
            let collectionViewYOffset = collectionView.contentOffset.y
            collectionView.contentOffset = CGPoint(x: collectionViewXOffset,y: collectionViewYOffset)
        }
        
        cellEstimatedCenterPoints = []
        cellEstimatedFrames = []
        for itemIndex in 0 ..< cellCount {
            var cellCenter: CGPoint = CGPoint(x: 0, y: 0)
            cellCenter.y = collectionViewHeight / 2.0
            cellCenter.x = collectionViewWidth * CGFloat(itemIndex) + collectionViewWidth  / 2.0
            cellEstimatedCenterPoints.append(cellCenter)
            cellEstimatedFrames.append(
                CGRect(origin: CGPoint(x: collectionViewWidth * CGFloat(itemIndex),
                                       y: 0),
                       size: CGSize(width: collectionViewWidth,
                                    height: collectionViewHeight))
            )
        }
        
        shouldLayoutEverything = false
    }
    
    var currentOffset: CGFloat {
        return (collectionView!.contentOffset.x + collectionView!.contentInset.left)
    }
    
    var currentCellIndex: Int {
        return min(cellCount - 1, Int(currentOffset / collectionViewWidth))
    }
    
    var currentFractionComplete: CGFloat {
        let relativeOffset = currentOffset / collectionViewWidth
        return modf(relativeOffset).1
    }
    
    override var collectionViewContentSize: CGSize {
        let contentWidth = collectionViewWidth * CGFloat(cellCount)
        let contentHeight = collectionViewHeight
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }
        
        switch indexPath.item {
        case currentCellIndex:
            attributes.size = CGSize(
                width: max(40, collectionViewWidth - cellSpacing * currentFractionComplete),
                height: collectionViewHeight
            )
            
        case currentCellIndex + 1:
            attributes.size = CGSize(
                width: max(40, collectionViewWidth - cellSpacing * (1 - currentFractionComplete)),
                height: collectionViewHeight
            )
            
        default:
            attributes.size = CGSize(width: collectionViewWidth, height: collectionViewHeight)
            
        }
        
        attributes.center = cellEstimatedCenterPoints[indexPath.row]
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
                
        var allAttributes: [UICollectionViewLayoutAttributes] = []
        for itemIndex in 0 ..< cellCount {
            if rect.intersects(cellEstimatedFrames[itemIndex]) {
                let indexPath = IndexPath(item: itemIndex, section: 0)
                let attributes = layoutAttributesForItem(at: indexPath)!
                allAttributes.append(attributes)
            }
        }
        return allAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)

        if newBounds.size != collectionView!.bounds.size {
            shouldLayoutEverything = true
        }
        return context
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateEverything || context.invalidateDataSourceCounts {
            shouldLayoutEverything = true
        }
        super.invalidateLayout(with: context)
    }
}
