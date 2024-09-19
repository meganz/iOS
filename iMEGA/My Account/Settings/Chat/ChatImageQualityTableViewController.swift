import MEGADesignToken
import MEGAL10n
import UIKit

class ChatImageQualityTableViewController: UITableViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.Localizable.imageQuality
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
            
            tableView.reloadData()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        tableView.separatorColor = UIColor.mnz_separator()
        tableView.backgroundColor = UIColor.pageBackgroundColor(for: traitCollection)
        
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.mnz_backgroundElevated()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let currentSeletedQuality = UserDefaults.standard.integer(forKey: "chatImageQuality")
        
        let imageView = UIImageView(image: UIImage.turquoiseCheckmark)
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
