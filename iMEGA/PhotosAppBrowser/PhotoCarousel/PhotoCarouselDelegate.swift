
import UIKit

class PhotoCarouselDelegate: PhotoGridViewDelegate {
    weak var viewController: PhotoCarouselViewController?
    
    init(viewController: PhotoCarouselViewController,
         collectionView: UICollectionView,
         cellsPerRow: @escaping () -> Int) {
        self.viewController = viewController
        super.init(collectionView: collectionView, cellsPerRow: cellsPerRow)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoCarouselCell {
            cell.willDisplay(size: collectionView.bounds.size)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoGridViewCell {
            cell.didEndDisplaying()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewController?.didSelectIndex(index: indexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width , height: collectionView.bounds.width)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let pageIndex = Int(scrollView.contentOffset.x / pageWidth)

        viewController?.didViewPage(atIndex: pageIndex)
    }
}
