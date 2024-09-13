import MEGADesignToken
import UIKit

extension RubbishBinTableViewController {
    @objc func showUpgradeToPro() {
        UpgradeAccountRouter().presentUpgradeTVC()
    }

    @objc func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)

        rubbishBinCleaningSchedulerLabel.textColor = TokenColors.Text.primary
        removeFilesOlderThanLabel.textColor = TokenColors.Text.primary
        clearRubbishBinDetailLabel.textColor = TokenColors.Text.secondary
        removeFilesOlderThanDetailLabel.textColor = TokenColors.Text.secondary
        clearRubbishBinLabel.textColor = TokenColors.Text.error

        setupTableViewHeaderAndFooter()
        tableView.reloadData()
    }
}
