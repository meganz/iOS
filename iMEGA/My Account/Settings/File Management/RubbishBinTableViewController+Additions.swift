import MEGADesignToken
import UIKit

extension RubbishBinTableViewController {
    @objc func showUpgradeToPro() {
        UpgradeAccountRouter().presentUpgradeTVC()
    }

    @objc func setupColors() {
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page

        rubbishBinCleaningSchedulerLabel.textColor = TokenColors.Text.primary
        removeFilesOlderThanLabel.textColor = TokenColors.Text.primary
        clearRubbishBinDetailLabel.textColor = TokenColors.Text.secondary
        removeFilesOlderThanDetailLabel.textColor = TokenColors.Text.secondary
        clearRubbishBinLabel.textColor = TokenColors.Text.error

        setupTableViewHeaderAndFooter()
    }
}
