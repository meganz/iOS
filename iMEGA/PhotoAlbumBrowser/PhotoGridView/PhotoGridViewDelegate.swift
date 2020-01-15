
import UIKit

class PhotoGridViewDelegate: NSObject {
    let collectionView: UICollectionView
    let cellsPerRow: () -> Int
    
    init(collectionView: UICollectionView, cellsPerRow: @escaping () -> Int) {
        self.collectionView = collectionView
        self.cellsPerRow = cellsPerRow
    }
}

extension PhotoGridViewDelegate {
    private var cellSize: CGSize {
        let cellWidth = collectionView.bounds.width / CGFloat(cellsPerRow())
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

extension PhotoGridViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoGridViewCell {
            cell.willDisplay(size: cellSize)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotoGridViewCell {
            cell.didEndDisplaying()
        }
    }
}

extension PhotoGridViewDelegate: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
}


