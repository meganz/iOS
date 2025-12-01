import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift

extension OfflineTableViewViewController {
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAppearanceForTraitCollection()
    }
    
    @objc func configureDeleteContextMenu(_ contextMenu: UIContextualAction) -> UIContextualAction {
        let tintColor = TokenColors.Text.onColor
        contextMenu.image = MEGAAssets.UIImage.delete.withTintColor(tintColor)
        contextMenu.backgroundColor = TokenColors.Support.error
        return contextMenu
    }
    
    @objc func tableView(_ tableView: UITableView,
                         contextMenuConfigurationForRowAt indexPath: IndexPath,
                         itemPath: String) -> UIContextMenuConfiguration? {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            if isDirectory.boolValue {
                let offlineVC = self.storyboard?.instantiateViewController(withIdentifier: "OfflineViewControllerID") as? OfflineViewController
                offlineVC?.folderPathFromOffline = self.offline?.folderPath(fromOffline: itemPath, folder: itemPath.lastPathComponent)
                return offlineVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: MEGAAssets.UIImage.selectItem) { _ in
                self.setTableViewEditing(true, animated: true)
                self.tableView?.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
                self.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            return UIMenu(title: "", children: [selectAction])
        }
        
        return contextMenuConfiguration
    }
    
    @objc func willPerformPreviewActionForMenuWith(animator: any UIContextMenuInteractionCommitAnimating) {
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
            cell.thumbnailPlayImageView.isHidden = !isVideoExtension
        }
    }
    @objc(updateAppearance)
    func updateAppearanceForTraitCollection() {
        self.tableView?.backgroundColor = TokenColors.Background.page
        self.tableView?.separatorColor = TokenColors.Border.strong
    }
    
    @objc func makeFooterView() -> UIView {
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            return .init(frame: CGRect(x: 0, y: 0, width: tableView?.bounds.size.width ?? 0.0, height: 100))
        } else {
            return .init(frame: .zero)
        }
    }
}

extension OfflineTableViewViewController: OfflineHeaderViewHosting {}
