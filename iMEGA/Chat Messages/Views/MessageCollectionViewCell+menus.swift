import MessageKit

extension MessageCollectionViewCell {
    func isLastSectionVisible(collectionView: UICollectionView) -> Bool {
        let numberOfSections = collectionView.numberOfSections
        guard numberOfSections > 0 else { return true }
        let lastIndexPath = IndexPath(item: 0, section: numberOfSections - 1)
        return collectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
}
