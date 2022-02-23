import Foundation

protocol MiniPlayerActionsDelegate: AnyObject {
    func play(index: IndexPath)
    func showPlayer(node: MEGANode, filePath: String?)
    func showPlayer(filePath: String?)
}

final class MiniPlayerDelegate: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    private weak var delegate: MiniPlayerActionsDelegate?
    private let loopMode: Bool
    private let itemsNumber: Int
    private var lastContentOffset: CGPoint?
    
    init(delegate: MiniPlayerActionsDelegate, loopMode: Bool = false, itemsNumber: Int) {
        self.delegate = delegate
        self.loopMode = loopMode
        self.itemsNumber = itemsNumber
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        let itemAttrib = collectionView.layoutAttributesForItem(at: collectionView.indexPathsForVisibleItems.first ?? IndexPath(row: 0, section: 0))
        return itemAttrib?.frame.origin ?? proposedContentOffset
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? UICollectionView else {
            return
        }
        
        let collectionViewCenterX = collectionView.frame.width / CGFloat(2.0)
        let collectionViewCenterY = collectionView.frame.height / CGFloat(2.0)
        let collectionViewCenter = CGPoint(x: collectionView.contentOffset.x + collectionViewCenterX, y: collectionViewCenterY)
        guard let currentIndexPath = collectionView.indexPathForItem(at: collectionViewCenter) else {
            return
        }
        
        didScrollFinish(at: currentIndexPath, in: collectionView)
    }
    
    private func didScrollFinish(at currentIndexPath: IndexPath, in collectionView: UICollectionView) {
        let lastIndexPath = lastContentOffset.flatMap { collectionView.indexPathForItem(at: $0) }
        
        if loopMode, currentIndexPath.row == itemsNumber {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        } else if lastIndexPath != currentIndexPath || lastIndexPath == IndexPath(row: 0, section: 0) {
            delegate?.play(index: currentIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MiniPlayerItemCollectionViewCell else { return }
        if let node = cell.item?.node {
            delegate?.showPlayer(node: node, filePath: cell.item?.url.absoluteString)
        } else {
            delegate?.showPlayer(filePath: cell.item?.url.absoluteString)
        }
    }
}
