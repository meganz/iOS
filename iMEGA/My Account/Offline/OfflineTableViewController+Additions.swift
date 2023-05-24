import MEGASwift
import MEGADomain

extension OfflineTableViewViewController {
    @objc func tableView(_ tableView: UITableView,
                         contextMenuConfigurationForRowAt indexPath: IndexPath,
                         itemPath: String) -> UIContextMenuConfiguration? {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            if isDirectory.boolValue {
                let offlineVC = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewControllerID") as? OfflineViewController
                offlineVC?.folderPathFromOffline = self.offline.folderPath(fromOffline: itemPath, folder: itemPath.lastPathComponent)
                return offlineVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: Asset.Images.ActionSheetIcons.select.image) { _ in
                self.setTableViewEditing(true, animated: true)
                self.tableView?.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
                self.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
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
    
    @objc func refreshThumbnailImage(
        for cell: OfflineTableViewCell,
        thumbnailFilePath: String,
        nodeName: String
    ) {
        if let thumbnailImage = UIImage(contentsOfFile: thumbnailFilePath) {
            let isVideoExtension = VideoFileExtensionEntity()
                .videoSupportedExtensions.contains(nodeName.pathExtension)
            
            cell.thumbnailImageView.image = thumbnailImage
            cell.thumbnailImageView.isHidden = !isVideoExtension
        }
    }
}
