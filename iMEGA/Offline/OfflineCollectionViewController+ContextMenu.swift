extension OfflineCollectionViewController {
    @objc func collectionView(_ collectionView: UICollectionView,
                              contextMenuConfigurationForItemAt indexPath: IndexPath,
                              itemPath: String) -> UIContextMenuConfiguration? {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            if isDirectory.boolValue {
                let offlineVC = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewControllerID") as? OfflineViewController
                let url = URL(fileURLWithPath: itemPath)
                offlineVC?.folderPathFromOffline = self.offline.folderPath(fromOffline: itemPath, folder: url.lastPathComponent)
                return offlineVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: Asset.Images.ActionSheetIcons.select.image) { _ in
                self.setCollectionViewEditing(true, animated: true)
                self.collectionView?.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
            }
            return UIMenu(title: "", children: [selectAction])
        }

        return contextMenuConfiguration
    }
    
    @objc func willPerformPreviewActionForMenuWith(animator: UIContextMenuInteractionCommitAnimating) {
        guard let offlineVC = animator.previewViewController as? OfflineViewController else { return }
        animator.addCompletion {
            self.navigationController?.pushViewController(offlineVC, animated: true)
        }
    }
}
