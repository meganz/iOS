import MEGADesignToken
import UIKit

extension QRSettingsTableViewController {
    @objc func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            autoAcceptLabel?.textColor = TokenColors.Text.primary
            resetQRCodeLabel?.textColor = TokenColors.Text.error
            tableView.separatorColor = TokenColors.Border.strong
            tableView.backgroundColor = TokenColors.Background.page
        } else {
            autoAcceptLabel?.textColor = UIColor.label
            resetQRCodeLabel?.textColor = UIColor.mnz_errorRed(for: traitCollection)
            tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
            tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        }
        tableView.reloadData()
    }
    
    open override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_backgroundElevated(traitCollection)
    }
}
