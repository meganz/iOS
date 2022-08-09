
extension FolderLinkCollectionViewController: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let collectionView = collectionView,
              let node = getNode(at: indexPath) else { return nil }
        
        let cell = indexPath.section == ThumbnailSection.file.rawValue ?
                                                        NodeCollectionViewCell.instantiateFromFileNib :
                                                        NodeCollectionViewCell.instantiateFromFolderNib
        
        cell.configureCell(forFolderLinkNode: node, allowedMultipleSelection: collectionView.allowsMultipleSelection, sdk: MEGASdkManager.sharedMEGASdk(), delegate: nil)
        
        return cell
    }
}
