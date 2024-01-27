import MEGADesignToken
import MEGAPresentation
import UIKit

extension FileManagementTableViewController {
    @objc func updateLabelAppearance() {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) {
            clearOfflineFilesLabel.textColor = TokenColors.Text.primary
            clearCacheLabel.textColor = TokenColors.Text.primary
            fileVersioningLabel.textColor = TokenColors.Text.primary
            fileVersioningDetail.textColor = TokenColors.Text.primary
            useMobileDataLabel.textColor = TokenColors.Text.primary
        }
    }

    open override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }

        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) {
            headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
        }
    }

    open override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let headerFooterView = view as? UITableViewHeaderFooterView else { return }

        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) {
            headerFooterView.textLabel?.textColor = TokenColors.Text.secondary
        }
    }
}
