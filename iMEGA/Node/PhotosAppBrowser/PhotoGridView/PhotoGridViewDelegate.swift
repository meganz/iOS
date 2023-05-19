
import UIKit

class PhotoGridViewDelegate: NSObject {
    private let collectionView: UICollectionView
    private let cellsPerRow: () -> Int
    var isMultiSelectionEnabled: ((Bool) -> Void)?
    var updateBottomView: (() -> Void)?
    private var selecting: Bool = true
    
    // MARK:- Initializer.
    
    init(collectionView: UICollectionView, cellsPerRow: @escaping () -> Int) {
        self.collectionView = collectionView
        self.cellsPerRow = cellsPerRow
    }
}

// MARK:- Private methods.

private extension PhotoGridViewDelegate {
    var cellSize: CGSize {
        let cellWidth = collectionView.bounds.width / cellsCountPerRow
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    var cellsCountPerRow: CGFloat {
        let count = cellsPerRow()
        return CGFloat(count)
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
    
    func collectionView(_ collectionView: UICollectionView,
                        shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        isMultiSelectionEnabled?(true)
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        isMultiSelectionEnabled?(false)
        updateBottomView?()
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
