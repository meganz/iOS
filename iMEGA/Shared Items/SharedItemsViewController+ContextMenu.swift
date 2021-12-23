import Foundation
extension SharedItemsViewController {
    @objc func tableView(_ tableView: UITableView,
                         contextMenuConfigurationForRowAt indexPath: IndexPath,
                         node: MEGANode) -> UIContextMenuConfiguration? {
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            if node.isFolder() {
                let cloudDriveVC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController
                cloudDriveVC?.parentNode = node
                cloudDriveVC?.displayMode = .cloudDrive
                return cloudDriveVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: Asset.Images.ActionSheetIcons.select.image) { _ in
                self.didTapSelect()
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            }
            return UIMenu(title: "", children: [selectAction])
        }

        return contextMenuConfiguration
    }
    
    @objc func willPerformPreviewActionForMenuWith(animator: UIContextMenuInteractionCommitAnimating) {
        guard let cloudDriveVC = animator.previewViewController as? CloudDriveViewController else { return }
        animator.addCompletion {
            self.navigationController?.pushViewController(cloudDriveVC, animated: true)
        }
    }
}
