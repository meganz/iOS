import MEGAAssets
import MEGAL10n
import MEGASwift

extension OfflineCollectionViewController {
    @objc func collectionView(_ collectionView: UICollectionView,
                              contextMenuConfigurationForItemAt indexPath: IndexPath,
                              itemPath: String) -> UIContextMenuConfiguration? {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
        
        return UIContextMenuConfiguration(identifier: nil) {
            if isDirectory.boolValue {
                let offlineVC = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewControllerID") as? OfflineViewController
                offlineVC?.folderPathFromOffline = self.offline.folderPath(fromOffline: itemPath, folder: itemPath.lastPathComponent)
                return offlineVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            UIMenu(
                title: "",
                children: [self.makeSelectAction(for: indexPath, in: collectionView)]
            )
        }
    }
    
    @objc func willPerformPreviewActionForMenuWith(animator: any UIContextMenuInteractionCommitAnimating) {
        guard let offlineVC = animator.previewViewController as? OfflineViewController else { return }
        animator.addCompletion {
            self.navigationController?.pushViewController(offlineVC, animated: true)
        }
    }
    
    private func makeSelectAction(
        for indexPath: IndexPath,
        in collectionView: UICollectionView
    ) -> UIAction {
        UIAction(
            title: Strings.Localizable.select,
            image: MEGAAssets.UIImage.selectItem
        ) { [weak self] _ in
            self?.performSelectAction(at: indexPath, in: collectionView)
        }
    }
    
    private func performSelectAction(
        at indexPath: IndexPath,
        in collectionView: UICollectionView
    ) {
        guard (collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) == false else { return }
        
        setCollectionViewEditing(true, animated: true)
        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
}
