import Foundation

extension UICollectionView {
    @objc func clearSelectedItems(animated: Bool = false) {
        indexPathsForSelectedItems?.forEach({ (indexPath) in
            deselectItem(at: indexPath, animated: animated)
        })
        reloadItems(at: indexPathsForVisibleItems)
    }
    
    @objc func isValid(indexPath: IndexPath) -> Bool {
        guard indexPath.section < numberOfSections,
              indexPath.row < numberOfItems(inSection: indexPath.section)  else { return false }
        return true
    }
}
