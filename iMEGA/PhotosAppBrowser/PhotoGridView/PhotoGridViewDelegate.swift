
import UIKit

class PhotoGridViewDelegate: NSObject {
    private let collectionView: UICollectionView
    private let cellsPerRow: () -> Int
    
    // MARK:- Initializer.
    
    init(collectionView: UICollectionView, cellsPerRow: @escaping () -> Int) {
        self.collectionView = collectionView
        self.cellsPerRow = cellsPerRow
    }
}

// MARK:- Private methods.

extension PhotoGridViewDelegate {
    private var cellSize: CGSize {
        let number: CGFloat = CGFloat(cellsPerRow())
        let cellWidth: CGFloat = collectionView.bounds.width / number
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK:- UICollectionViewDelegate.

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

// MARK:- UICollectionViewDelegateFlowLayout.

extension PhotoGridViewDelegate: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
       cellSize
    }
}

