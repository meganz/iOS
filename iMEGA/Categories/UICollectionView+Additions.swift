import Foundation

extension UICollectionView {
    @objc func clearSelectedItems(animated: Bool = false) {
        indexPathsForSelectedItems?.forEach({ (indexPath) in
            deselectItem(at: indexPath, animated: animated)
        })
        reloadItems(at: indexPathsForVisibleItems)
    }
}
