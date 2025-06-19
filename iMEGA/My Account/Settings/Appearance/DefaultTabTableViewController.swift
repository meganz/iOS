import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

final class DefaultTabTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Localizable.defaultTab
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TabManager.avaliableTabs
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        
        if let tabType = TabType(rawValue: indexPath.row) {
            let tab = Tab(tabType: tabType)
            cell.imageView?.image = tab.icon.withTintColor(TokenColors.Text.secondary)
            let title = tab.title
            cell.textLabel?.text = Strings.localized(title, comment: title)
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.textColor = UIColor.primaryTextColor()
        }
        cell.accessoryView = UIImageView(image: MEGAAssets.UIImage.turquoiseCheckmark)
        cell.backgroundColor = TokenColors.Background.page
        cell.accessoryView?.isHidden = TabManager.getPreferenceTab().tabType.rawValue != indexPath.row
        
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let tabType = TabType(rawValue: indexPath.row) {
            TabManager.setPreferenceTab(tab: Tab(tabType: tabType))
            tableView.reloadData()
        }
    }
}
