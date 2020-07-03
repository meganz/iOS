
import PanModal

protocol ReactedEmojisUsersListViewControllerDelegate: class {
    func didSelectUserhandle(_ userhandle: UInt64)
}

class ReactedEmojisUsersListViewController: UIViewController  {
    
    var selectedEmoji: String {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            headerView.selectedEmoji = selectedEmoji
            updateEmojiHeaderViewDescription()
        }
    }
    
    private let chatId: UInt64
    private let messageId: UInt64
    private let emojiList: [String]
    private let localSavedEmojis = EmojiListReader.readFromFile()
    private weak var delegate: ReactedEmojisUsersListViewControllerDelegate?

    init(delegate: ReactedEmojisUsersListViewControllerDelegate,
         emojiList: [String],
         selectedEmoji: String,
         chatId: UInt64,
         messageId: UInt64) {
        self.delegate = delegate
        self.emojiList = emojiList
        self.selectedEmoji = selectedEmoji
        self.chatId = chatId
        self.messageId = messageId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let headerView = EmojiCarousalView.instanceFromNib
    lazy var reactedUsersListPageViewController: ReactedUsersListPageViewController = {
        let viewController = ReactedUsersListPageViewController(transitionStyle: .scroll,
                                                                navigationOrientation: .horizontal,
                                                                options: nil)
        viewController.usersListDelegate = self
        return viewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: 400, height: 600)

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        addHeaderView(emojiList: emojiList)
        headerView.selectedEmoji = selectedEmoji
        let userHandleList = userhandleList(forEmoji: selectedEmoji, chatId: chatId, messageId: messageId)
        updateEmojiHeaderViewDescription()
        guard let foundIndex = emojiList.firstIndex(of: selectedEmoji) else {
            fatalError("Selected emoji is not present in the emoji list")
        }
        reactedUsersListPageViewController.set(numberOfPages: emojiList.count,
                                               selectedPage: foundIndex,
                                               initialUserHandleList: userHandleList)
        add(viewController: reactedUsersListPageViewController)

    }
    
    private func updateEmojiHeaderViewDescription() {
        if let selectedEmojiName = localSavedEmojis?.filter({ $0.representation == selectedEmoji }).first?.displayString {
            let handleList = userhandleList(forEmoji: selectedEmoji, chatId: chatId, messageId: messageId)
            let description = String(format: AMLocalizedString("%d reacted to %@", "Chat reactions: number of users reacted to a emoji"),
                                     handleList.count,
                                     selectedEmojiName)
            headerView.updateDescription(text: description)
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
    
    private func userhandleList(forEmoji emoji: String, chatId: UInt64, messageId: UInt64) -> [UInt64] {
        guard let userHandleList =  MEGASdkManager
            .sharedMEGAChatSdk()?
            .getReactionUsers(forChat: chatId, messageId: messageId, reaction: emoji) else {
                MEGALogDebug("user handle list for emoji \(emoji) is empty")
            return []
        }
        
        return (0..<userHandleList.size).compactMap { userHandleList.megaHandle(at: $0) }
    }
}

extension ReactedEmojisUsersListViewController: EmojiCarousalViewDelegate {
    func didSelect(emoji: String, atIndex index: Int) {
        let userHandleList = userhandleList(forEmoji: emoji, chatId: chatId, messageId: messageId)
        reactedUsersListPageViewController.didSelectPage(withIndex: index, userHandleList: userHandleList)
        selectedEmoji = emoji
    }
}

extension ReactedEmojisUsersListViewController: ReactedUsersListPageViewControllerDelegate {
    func userHandleList(atIndex index: Int) -> [UInt64] {
        return userhandleList(forEmoji: emojiList[index], chatId: chatId, messageId: messageId)
    }
    
    func pageChanged(toIndex index: Int) {
        selectedEmoji = emojiList[index]
    }
    
    func didSelectUserhandle(_ userhandle: UInt64) {
        guard let myHandle = MEGASdkManager.sharedMEGASdk()?.myUser?.handle,
            myHandle != userhandle else {
                MEGALogDebug("My user handle tapped on chat reactions screen")
                return
        }
        
        dismiss(animated: true, completion: nil)
        delegate?.didSelectUserhandle(userhandle)
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
        return .contentHeight(300.0)
    }

    var anchorModalToLongForm: Bool {
        return false
    }
}
