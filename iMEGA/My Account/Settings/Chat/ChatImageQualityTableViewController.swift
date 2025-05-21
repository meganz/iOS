import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

class ChatImageQualityTableViewController: UITableViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.Localizable.imageQuality
        
        setupColors()
    }
    
    // MARK: - Private
    
    private func setupColors() {
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let currentSeletedQuality = UserDefaults.standard.integer(forKey: "chatImageQuality")
        
        let imageView = UIImageView(image: MEGAAssets.UIImage.turquoiseCheckmark)
        imageView.tintColor = TokenColors.Support.success
        
        cell.accessoryView = imageView
        cell.accessoryView?.isHidden = currentSeletedQuality != indexPath.row

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = Strings.Localizable.Media.Quality.automatic
            cell.detailTextLabel?.text = Strings.Localizable.sendSmallerSizeImagesThroughCellularNetworksAndOriginalSizeImagesThroughWifi

        case 1:
            cell.textLabel?.text = Strings.Localizable.Media.Quality.original
            cell.detailTextLabel?.text = Strings.Localizable.sendOriginalSizeIncreasedQualityImages

        case 2:
            cell.textLabel?.text = Strings.Localizable.Media.Quality.optimised
            cell.detailTextLabel?.text = Strings.Localizable.sendSmallerSizeImagesOptimisedForLowerDataConsumption
        
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
