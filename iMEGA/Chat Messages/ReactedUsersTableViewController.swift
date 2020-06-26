

import UIKit

class ReactedUsersTableViewController: UITableViewController {
    private let contactCellReuseIdentifier = "contactCellReuseIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: contactCellReuseIdentifier)
        tableView.rowHeight = 60.0
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: Replace this with the actual model.
        return 10
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: contactCellReuseIdentifier,
                                                 for: indexPath)
        // TODO: Replace this with the actual model.
        cell.textLabel?.text = "User"
        return cell
    }
    
}
