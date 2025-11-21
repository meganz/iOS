extension OfflineCollectionViewController: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let collectionView = collectionView,
              let item = self.getItemAt(indexPath),
              let itemPath = offline?.currentOfflinePath.appending("kFileName") else {
            return nil
        }

        let cell = NodeCollectionViewCell.instantiateFromNib

        cell.configureCell(
            forOfflineItem: item,
            itemPath: itemPath,
            allowedMultipleSelection: collectionView.allowsMultipleSelection,
            sdk: .shared,
            delegate: nil
        )
        
        return cell
    }
}
