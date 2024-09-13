import MEGADesignToken
import UIKit

extension QRSettingsTableViewController {
    @objc func updateAppearance() {
        autoAcceptLabel?.textColor = TokenColors.Text.primary
        resetQRCodeLabel?.textColor = TokenColors.Text.error
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
        tableView.reloadData()
    }
    
    open override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.backgroundColor = TokenColors.Background.page
    }
}
