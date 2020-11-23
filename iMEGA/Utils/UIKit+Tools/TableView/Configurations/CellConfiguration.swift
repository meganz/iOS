import Foundation

struct CellConfiguration {

    let cellIdentifier: String

    private var nib: UINib {
        UINib(
            nibName: cellIdentifier + "TableViewCell",
            bundle: nil
        )
    }

    func registerCell(in tableView: UITableView) {
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
    }

    func dequeuedCell(
        in tableView: UITableView,
        for indexPath: IndexPath
    ) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    }
}
