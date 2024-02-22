import MEGADesignToken
import UIKit

extension RubbishBinTableViewController {
    @objc func showUpgradeToPro() {
        UpgradeAccountRouter().presentUpgradeTVC()
    }

    @objc func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)

        if UIColor.isDesignTokenEnabled() {
            rubbishBinCleaningSchedulerLabel.textColor = TokenColors.Text.primary
            removeFilesOlderThanLabel.textColor = TokenColors.Text.primary
            clearRubbishBinDetailLabel.textColor = TokenColors.Text.secondary
            removeFilesOlderThanDetailLabel.textColor = TokenColors.Text.secondary
            clearRubbishBinLabel.textColor = TokenColors.Text.error
        } else {
            clearRubbishBinLabel.textColor = UIColor.mnz_red(for: traitCollection)
            clearRubbishBinDetailLabel.textColor = UIColor.secondaryLabel
            removeFilesOlderThanDetailLabel.textColor = UIColor.secondaryLabel
        }

        setupTableViewHeaderAndFooter()
        tableView.reloadData()
    }
}
