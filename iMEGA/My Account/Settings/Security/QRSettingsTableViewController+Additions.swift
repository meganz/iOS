import MEGADesignToken
import UIKit

extension QRSettingsTableViewController {
    @objc func setupColors() {
        autoAcceptLabel?.textColor = TokenColors.Text.primary
        resetQRCodeLabel?.textColor = TokenColors.Text.error
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
    }
    
    open override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.backgroundColor = TokenColors.Background.page
    }
}
