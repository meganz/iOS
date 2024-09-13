import MEGADesignToken
import UIKit

protocol RegionListSource: UITableViewDataSource {
    func country(at indexPath: IndexPath) -> SMSRegion
}

extension RegionListSource {
    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countryCell", for: indexPath)
        cell.textLabel?.text = country(at: indexPath).displayName
        cell.textLabel?.textColor = TokenColors.Text.primary
        cell.backgroundColor = TokenColors.Background.page

        return cell
    }
}
