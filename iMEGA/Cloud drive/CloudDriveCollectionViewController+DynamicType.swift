import Foundation

extension CloudDriveCollectionViewController: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let collectionView = collectionView,
              let node = thumbnailNode(at: indexPath) else { return nil }
        
        let cell = indexPath.section == ThumbnailSection.file.rawValue ?
                                                        NodeCollectionViewCell.instantiateFromFileNib :
                                                        NodeCollectionViewCell.instantiateFromFolderNib
        
        cell.configureCell(
            for: node,
            allowedMultipleSelection: collectionView.allowsMultipleSelection,
            isFromSharedItem: cloudDrive?.isFromSharedItem ?? false,
            sdk: MEGASdk.shared,
            delegate: nil)
        
        return cell
    }
}
