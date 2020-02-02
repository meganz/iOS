import UIKit


class ChatImageQualityTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Image quality", comment: "Label used near to the option selected to encode the images uploaded to a chat (Low, Medium, Original)")
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let currentSeletedQuality = UserDefaults.standard.integer(forKey: "chatImageQuality")

        cell.accessoryView = UIImageView.init(image: #imageLiteral(resourceName: "red_checkmark"))
        cell.accessoryView?.isHidden = currentSeletedQuality != indexPath.row

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = NSLocalizedString("Automatic", comment: "Label indicating that Send smaller size images through cellular networks and original size images through wifi")
            cell.detailTextLabel?.text = NSLocalizedString("Send smaller size images through cellular networks and original size images through wifi", comment: "Description of Automatic Image Quality option")

        case 1:
            cell.textLabel?.text = NSLocalizedString("High", comment: "High")
            cell.detailTextLabel?.text = NSLocalizedString("Send original size, increased quality images", comment: "Description of High Image Quality option")

        case 2:
            cell.textLabel?.text = NSLocalizedString("Optimised", comment: "Optimised")
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
}
