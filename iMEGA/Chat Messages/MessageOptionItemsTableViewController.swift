

import UIKit

protocol MessageOptionItemsTableViewControllerDataSource: class {
    func numberOfItems(forViewController viewController: MessageOptionItemsTableViewController) -> Int
    func setImageView(_ imageView: UIImageView, forIndex index: Int, viewController: MessageOptionItemsTableViewController)
    func setLabel(_ label: UILabel, forIndex index: Int, viewController: MessageOptionItemsTableViewController)
}

class MessageOptionItemsTableViewController: UITableViewController {
    
    weak var messageOptionItemsDataSource: MessageOptionItemsTableViewControllerDataSource? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.register(MessageOptionItemTableCell.nib,
                           forCellReuseIdentifier: MessageOptionItemTableCell.reuseIdentifier)
        tableView.rowHeight = 60.0
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageOptionItemsDataSource?.numberOfItems(forViewController: self) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageOptionItemTableCell.reuseIdentifier,
                                                       for: indexPath) as? MessageOptionItemTableCell else {
                                                        fatalError("Could not dequeue cell ReactedContactTableCell")
        }
        
        cell.index = indexPath.row
        cell.delegate = self
        
        return cell
    }
    
}

extension MessageOptionItemsTableViewController: MessageOptionItemTableCellDelegate {
    func setImageView(_ imageView: UIImageView, forIndex index: Int) {
        messageOptionItemsDataSource?.setImageView(imageView, forIndex: index, viewController: self)
    }
    
    func setLabel(_ label: UILabel, forIndex index: Int) {
        messageOptionItemsDataSource?.setLabel(label, forIndex: index, viewController: self)
    }
}

