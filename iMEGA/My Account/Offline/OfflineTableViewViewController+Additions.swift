import MEGADesignToken
import UIKit

extension OfflineTableViewViewController {
    @objc func configureDeleteContextMenu(_ contextMenu: UIContextualAction) -> UIContextualAction {
        let tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.onColor : UIColor.mnz_whiteFFFFFF()
        contextMenu.image = UIImage(resource: .delete).withTintColor(tintColor)
        contextMenu.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Support.error : .systemRed
        return contextMenu
    }
}
