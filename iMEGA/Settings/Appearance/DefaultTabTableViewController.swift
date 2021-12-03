
import UIKit

final class DefaultTabTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Localizable.defaultTab
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
    }

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TabManager.avaliableTabs
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        
        if let tabType = TabType(rawValue: indexPath.row) {
            let tab = Tab(tabType: tabType)
            cell.imageView?.image = tab.icon?.byTintColor(UIColor.mnz_primaryGray(for: traitCollection))
            let title = tab.title
            cell.textLabel?.text = NSLocalizedString(title, comment: title)
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        }
        cell.accessoryView = UIImageView(image: Asset.Images.Generic.turquoiseCheckmark.image)
        cell.backgroundColor = UIColor.mnz_secondaryBackgroundGrouped(traitCollection)
        cell.accessoryView?.isHidden = TabManager.getPreferenceTab().tabType.rawValue != indexPath.row
        
        return cell;
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
