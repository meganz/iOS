
import PanModal


protocol ReactedEmojisUsersListViewControllerDataSource: class {
    var emojiList: [String] { get }
    func userhandleList(forEmoji: String) -> [UInt64]
}

class ReactedEmojisUsersListViewController: UIViewController  {

    var isShortFormEnabled = true
    let headerView = EmojiCarousalView.instanceFromNib
    lazy var reactedUsersTableViewController = ReactedUsersTableViewController(nibName: nil, bundle: nil)
    var reactedUsersListPages: [ReactedUsersListPageViewController]?

    weak var dataSource: ReactedEmojisUsersListViewControllerDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dataSource = dataSource {
            addHeaderView(emojiList: dataSource.emojiList)
            addReactedUsersTableViewController()
        } else {
            fatalError("empty emoji list is not handled yet.")
        }
    }
    
    private func addHeaderView(emojiList: [String]) {
        headerView.emojiList = emojiList
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerView.bounds.height)
        ])
    }
    
    private func addReactedUsersTableViewController() {
        addChild(reactedUsersTableViewController)
        view.addSubview(reactedUsersTableViewController.view)
        
        reactedUsersTableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reactedUsersTableViewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            reactedUsersTableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reactedUsersTableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            reactedUsersTableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        reactedUsersTableViewController.didMove(toParent: self)
    }
}

// MARK: - Pan Modal Presentable

extension ReactedEmojisUsersListViewController: PanModalPresentable {

    var panScrollable: UIScrollView? {
        return reactedUsersTableViewController.tableView
    }
    
    var showDragIndicator: Bool {
        return false
    }

    var shortFormHeight: PanModalHeight {
        return isShortFormEnabled ? .contentHeight(300.0) : longFormHeight
    }

    var scrollIndicatorInsets: UIEdgeInsets {
        let bottomOffset = presentingViewController?.bottomLayoutGuide.length ?? 0
        return UIEdgeInsets(top: headerView.frame.size.height, left: 0, bottom: bottomOffset, right: 0)
    }

    var anchorModalToLongForm: Bool {
        return false
    }

    func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let location = panModalGestureRecognizer.location(in: view)
        return headerView.frame.contains(location)
    }

    func willTransition(to state: PanModalPresentationController.PresentationState) {
        guard isShortFormEnabled, case .longForm = state
            else { return }

        isShortFormEnabled = false
        panModalSetNeedsLayoutUpdate()
    }
}
