import UIKit


class ChatImageQualityTableViewController: UITableViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Image Quality", comment: "Label used near to the option selected to encode the images uploaded to a chat (Low, Medium, Original)")
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
                
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.mnz_secondaryBackgroundGrouped(traitCollection)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let currentSeletedQuality = UserDefaults.standard.integer(forKey: "chatImageQuality")

        cell.accessoryView = UIImageView.init(image: #imageLiteral(resourceName: "turquoise_checkmark"))
        cell.accessoryView?.isHidden = currentSeletedQuality != indexPath.row

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = NSLocalizedString("Automatic", comment: "Label indicating that Send smaller size images through cellular networks and original size images through wifi")
            cell.detailTextLabel?.text = NSLocalizedString("Send smaller size images through cellular networks and original size images through wifi", comment: "Description of Automatic Image Quality option")

        case 1:
            cell.textLabel?.text = NSLocalizedString("high", comment: "Property associated with something higher than the usual or average size, number, value, or amount. For example: video quality.")
            cell.detailTextLabel?.text = NSLocalizedString("Send original size, increased quality images", comment: "Description of High Image Quality option")

        case 2:
            cell.textLabel?.text = NSLocalizedString("Optimised", comment: "Text for some option property indicating the user the action to perform will be optimised. For example: Image Quality reduction option for chats")
            cell.detailTextLabel?.text = NSLocalizedString("Send smaller size images optimised for lower data consumption", comment: "Description of Optimised Image Quality option")
        
        default:
            return cell
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.set(indexPath.row, forKey: "chatImageQuality")
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
