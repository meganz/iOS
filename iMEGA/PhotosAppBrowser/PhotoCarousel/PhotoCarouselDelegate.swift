
import UIKit

final class PhotoCarouselDelegate: PhotoGridViewDelegate {
    weak var viewController: PhotoCarouselViewController?
    
    // MARK:- Initializer.

    init(viewController: PhotoCarouselViewController,
         collectionView: UICollectionView,
         cellsPerRow: @escaping () -> Int) {
        self.viewController = viewController
        super.init(collectionView: collectionView, cellsPerRow: cellsPerRow)
    }
    
    // MARK:- Overriden UICollectionViewDelegate methods.
    
    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoCarouselCell {
            cell.willDisplay(size: collectionView.bounds.size)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoCarouselCell {
            cell.didEndDisplaying()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width , height: collectionView.bounds.width)
    }
    
    // MARK:- Non-Overriden UICollectionViewDelegate methods.

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewController?.didSelectIndex(index: indexPath.item)
    }
    
    // MARK:- ScrollView delegate method.
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let pageIndex = Int(scrollView.contentOffset.x / pageWidth)

        viewController?.didViewPage(atIndex: pageIndex)
    }
}
