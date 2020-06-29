

import UIKit

class ReactedUsersTableViewController: UITableViewController {
    var userHandleList: [UInt64]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ReactedContactTableCell.nib,
                           forCellReuseIdentifier: ReactedContactTableCell.reuseIdentifier)
        tableView.rowHeight = 60.0
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userHandleList?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReactedContactTableCell.reuseIdentifier,
                                                       for: indexPath) as? ReactedContactTableCell else {
                                                        fatalError("Could not dequeue cell ReactedContactTableCell")
        }
        
        if let handleList = userHandleList {
            cell.userHandle = handleList[indexPath.row]
        }
        
        return cell
    }
    
}
