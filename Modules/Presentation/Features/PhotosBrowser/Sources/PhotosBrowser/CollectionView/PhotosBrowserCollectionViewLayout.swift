import UIKit

final class PhotosBrowserCollectionViewLayout: UICollectionViewFlowLayout {
    
    // MARK: - Life cycle
    
    override init() {
        super.init()
        
        scrollDirection = .horizontal
        minimumLineSpacing = 10.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        itemSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                             withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        
        let pageLength = itemSize.width + minimumLineSpacing
        let approxPage = collectionView.contentOffset.x / pageLength
        let speed = velocity.x
        
        let nextOrCurrentPage: CGFloat = if speed < 0 {
            ceil(approxPage)
        } else if speed > 0 {
            floor(approxPage)
        } else {
            round(approxPage)
        }
        
        guard speed != 0 else { return CGPoint(x: nextOrCurrentPage * pageLength, y: 0) }
        
        let nextPage: CGFloat = nextOrCurrentPage + (speed > 0 ? 1 : -1)
        
        return CGPoint(x: nextPage * pageLength, y: 0)
    }
}
