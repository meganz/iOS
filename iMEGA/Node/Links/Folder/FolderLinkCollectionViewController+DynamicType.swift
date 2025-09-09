extension FolderLinkCollectionViewController: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let collectionView = collectionView,
              let node = getNode(at: indexPath) else { return nil }
        
        let cell = NodeCollectionViewCell.instantiateFromNib

        cell.configureCell(for: node,
                           allowedMultipleSelection: collectionView.allowsMultipleSelection,
                           isFromSharedItem: false,
                           sdk: MEGASdk.shared,
                           delegate: self,
                           isSampleRow: true)
        return cell
    }
}
