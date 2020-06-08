import UIKit


class ChatImageQualityTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = AMLocalizedString("Image quality", "Label used near to the option selected to encode the images uploaded to a chat (Low, Medium, Original)")
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let currentSeletedQuality = UserDefaults.standard.integer(forKey: "chatImageQuality")

        cell.accessoryView = UIImageView.init(image: #imageLiteral(resourceName: "turquoise_checkmark"))
        cell.accessoryView?.isHidden = currentSeletedQuality != indexPath.row

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = AMLocalizedString("Automatic", "Label indicating that Send smaller size images through cellular networks and original size images through wifi")
            cell.detailTextLabel?.text = AMLocalizedString("Send smaller size images through cellular networks and original size images through wifi", "Description of Automatic Image Quality option")

        case 1:
            cell.textLabel?.text = AMLocalizedString("High", "High")
            cell.detailTextLabel?.text = AMLocalizedString("Send original size, increased quality images", "Description of High Image Quality option")

        case 2:
            cell.textLabel?.text = AMLocalizedString("Optimised", "Optimised")
            cell.detailTextLabel?.text = AMLocalizedString("Send smaller size images optimised for lower data consumption", "Description of Optimised Image Quality option")
        
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
