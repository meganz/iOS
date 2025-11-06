import Combine
import UIKit

final class PhotosBrowserCollectionViewLayout: UICollectionViewFlowLayout {
    let _pageIndexSubject = PassthroughSubject<Int, Never>()
    
    var pageIndexPublisher: AnyPublisher<Int, Never> {
        _pageIndexSubject.removeDuplicates().eraseToAnyPublisher()
    }
    
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
        
        guard speed != 0 else {
            let targetOffset = CGPoint(x: nextOrCurrentPage * pageLength, y: 0)
            updateCurrentIndex(collectionView, targetOffset: targetOffset)
            
            return targetOffset
        }
        
        let nextPage: CGFloat = nextOrCurrentPage + (speed > 0 ? 1 : -1)
        
        let targetOffset = CGPoint(x: nextPage * pageLength, y: 0)
        updateCurrentIndex(collectionView, targetOffset: targetOffset)
        
        return targetOffset
    }
    
    // MARK: - Private
    
    private func updateCurrentIndex(_ collectionView: UICollectionView, targetOffset: CGPoint) {
        let pageLength = itemSize.width + minimumLineSpacing
        let index = Int(targetOffset.x / pageLength)
        let newIndex = min(max(0, index), collectionView.numberOfItems(inSection: 0) - 1)
        
        _pageIndexSubject.send(newIndex)
    }
}
