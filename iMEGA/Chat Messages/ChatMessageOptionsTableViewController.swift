import MEGADesignToken
import UIKit

protocol ChatMessageOptionsTableViewControllerDataSource: AnyObject {
    func headerViewHeight() -> CGFloat
    func headerView() -> UIView?
    func numberOfItems(forViewController viewController: ChatMessageOptionsTableViewController) -> Int
    func setImageView(_ imageView: UIImageView, forIndex index: Int, viewController: ChatMessageOptionsTableViewController)
    func setLabel(_ label: UILabel, forIndex index: Int, viewController: ChatMessageOptionsTableViewController)
    func didSelect(cellAtIndex index: Int, viewController: ChatMessageOptionsTableViewController)
}

class ChatMessageOptionsTableViewController: UITableViewController {
    
    weak var chatMessageOptionDataSource: (any ChatMessageOptionsTableViewControllerDataSource)? {
        didSet {
            tableView.reloadData()
        }
    }
    
    init(chatMessageOptionDataSource: some ChatMessageOptionsTableViewControllerDataSource) {
        self.chatMessageOptionDataSource = chatMessageOptionDataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.register(MessageOptionItemTableCell.nib,
                           forCellReuseIdentifier: MessageOptionItemTableCell.reuseIdentifier)
        tableView.rowHeight = 60.0
        tableView.backgroundColor = TokenColors.Background.surface1
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessageOptionDataSource?.numberOfItems(forViewController: self) ?? 0
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
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = chatMessageOptionDataSource?.headerView()
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return chatMessageOptionDataSource?.headerViewHeight() ?? 0.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        chatMessageOptionDataSource?.didSelect(cellAtIndex: indexPath.row, viewController: self)
    }
}

extension ChatMessageOptionsTableViewController: MessageOptionItemTableCellDelegate {
    func setImageView(_ imageView: UIImageView, forIndex index: Int) {
        chatMessageOptionDataSource?.setImageView(imageView, forIndex: index, viewController: self)
    }
    
    func setLabel(_ label: UILabel, forIndex index: Int) {
        chatMessageOptionDataSource?.setLabel(label, forIndex: index, viewController: self)
    }
}
