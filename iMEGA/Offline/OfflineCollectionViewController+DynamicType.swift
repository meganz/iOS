
extension OfflineCollectionViewController: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let collectionView = collectionView,
              let item = self.getItemAt(indexPath) else { return nil }
        
        let cell = indexPath.section == ThumbnailSection.file.rawValue ?
                                                        NodeCollectionViewCell.instantiateFromFileNib :
                                                        NodeCollectionViewCell.instantiateFromFolderNib
        
        cell.configureCell(forOfflineItem: item, itemPath: offline.currentOfflinePath.appending("kFileName"), allowedMultipleSelection: collectionView.allowsMultipleSelection, sdk: MEGASdkManager.sharedMEGASdk(), delegate: nil)
        
        return cell
    }
}
