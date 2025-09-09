extension OfflineCollectionViewController: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let collectionView = collectionView,
              let item = self.getItemAt(indexPath) else { return nil }
        
        let cell = NodeCollectionViewCell.instantiateFromNib

        cell.configureCell(
            forOfflineItem: item,
            itemPath: offline.currentOfflinePath.appending("kFileName"),
            allowedMultipleSelection: collectionView.allowsMultipleSelection,
            sdk: .shared,
            delegate: nil
        )
        
        return cell
    }
}
