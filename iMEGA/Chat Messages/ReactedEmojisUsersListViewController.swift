
import PanModal


protocol ReactedEmojisUsersListViewControllerDataSource: class {
    func userhandleList(forEmoji: String, chatId: UInt64, messageId: UInt64) -> [UInt64]
}

class ReactedEmojisUsersListViewController: UIViewController  {
    
    weak var dataSource: ReactedEmojisUsersListViewControllerDataSource?
    var selectedEmoji: String {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            headerView.selectedEmoji = selectedEmoji
        }
    }
    
    let chatId: UInt64
    let messageId: UInt64
    let emojiList: [String]
    
    init(dataSource: ReactedEmojisUsersListViewControllerDataSource,
         emojiList: [String],
         selectedEmoji: String,
         chatId: UInt64,
         messageId: UInt64) {
        self.dataSource = dataSource
        self.emojiList = emojiList
        self.selectedEmoji = selectedEmoji
        self.chatId = chatId
        self.messageId = messageId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isShortFormEnabled = true
    let headerView = EmojiCarousalView.instanceFromNib
    lazy var reactedUsersListPageViewController = ReactedUsersListPageViewController(transitionStyle: .scroll,
                                                                                     navigationOrientation: .horizontal,
                                                                                     options: nil)

   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dataSource = dataSource {
            addHeaderView(emojiList: emojiList)
            headerView.selectedEmoji = selectedEmoji
            let userHandleList = dataSource.userhandleList(forEmoji: selectedEmoji, chatId: chatId, messageId: messageId)
            headerView.updateDescription(attributedString: NSAttributedString(string: "\(userHandleList.count) reacted to :placeholder:"))
            
            guard let firstEmoji = emojiList.first else {
                fatalError("Emoji list cannot be empty")
            }

            reactedUsersListPageViewController.set(numberOfPages: emojiList.count,
                                                   initialUserHandleList: dataSource.userhandleList(forEmoji: firstEmoji,
                                                                                                    chatId: chatId,
                                                                                                    messageId: messageId))
            add(viewController: reactedUsersListPageViewController)

        } else {
            fatalError("empty emoji list is not handled yet.")
        }
    }
    
    private func addHeaderView(emojiList: [String]) {
        headerView.delegate = self
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
    
    private func add(viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        viewController.didMove(toParent: self)
    }
}

extension ReactedEmojisUsersListViewController: EmojiCarousalViewDelegate {
    func didSelect(emoji: String, atIndex index: Int) {
        if let userHandleList = dataSource?.userhandleList(forEmoji: emoji, chatId: chatId, messageId: messageId) {
            reactedUsersListPageViewController.didSelectPage(withIndex: index, userHandleList: userHandleList)
            headerView.updateDescription(attributedString: NSAttributedString(string: "\(userHandleList.count) reacted to :placeholder:"))
        }
    }
}

// MARK: - Pan Modal Presentable

extension ReactedEmojisUsersListViewController: PanModalPresentable {

    var panScrollable: UIScrollView? {
        return reactedUsersListPageViewController.tableViewController?.tableView
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
