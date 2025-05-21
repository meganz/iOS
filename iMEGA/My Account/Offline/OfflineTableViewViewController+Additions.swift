import MEGAAssets
import MEGADesignToken
import UIKit

extension OfflineTableViewViewController {
    @objc func configureDeleteContextMenu(_ contextMenu: UIContextualAction) -> UIContextualAction {
        let tintColor = TokenColors.Text.onColor
        contextMenu.image = MEGAAssets.UIImage.delete.withTintColor(tintColor)
        contextMenu.backgroundColor = TokenColors.Support.error
        return contextMenu
    }
}
