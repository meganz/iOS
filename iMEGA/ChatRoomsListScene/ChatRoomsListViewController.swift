import SwiftUI
import Combine
import MEGAUIKit

@available(iOS 14.0, *)
final class ChatRoomsListViewController: UIViewController {
    var tableView: UITableView?

    var globalDNDNotificationControl: GlobalDNDNotificationControl?
    var myAvatarManager: MyAvatarManager?
    var contextMenuManager: ContextMenuManager?

    var addBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image, style: .plain, target: nil, action: nil)
    
    lazy var moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: nil, action: nil)
    
    var viewModel: ChatRoomsListViewModel

    private var subscriptions = Set<AnyCancellable>()

    lazy var hostingView = UIHostingController(rootView: ChatRoomsListView(viewModel:  viewModel))

    init(viewModel: ChatRoomsListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.globalDNDNotificationControl = GlobalDNDNotificationControl(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureContextMenuManager()
        configureListView()
        updateTitleView()
        initSubscriptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [moreBarButtonItem, addBarButtonItem]
        configureNavigationBarButtons(chatMode: viewModel.chatMode)
        refreshMyAvatar()
        viewModel.loadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureListView() {
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostingView.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingView.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingView.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
    
    private func updateTitleView() {
        if let statusString = viewModel.chatStatus?.toChatStatus().localizedIdentifier {
            navigationItem.titleView = UILabel().customNavigationBarLabel(title: viewModel.title, subtitle: statusString)
        } else {
            navigationItem.title = viewModel.title
        }
    }
    
    private func initSubscriptions() {
        subscriptions = [
            viewModel.$chatMode.sink(receiveValue: { [weak self] chatMode in
                self?.configureNavigationBarButtons(chatMode: chatMode)
            }),
            viewModel.$chatStatus.sink(receiveValue: { [weak self] chatStatus in
                self?.refreshContextMenuBarButton()
                self?.updateTitleView()
            })
        ]
    }
    
    @objc func addBarButtonItemTapped() {
        viewModel.addChatButtonTapped()
    }
}

@available(iOS 14.0, *)
extension ChatRoomsListViewController: MyAvatarPresenterProtocol {
    func setupMyAvatar(barButton: UIBarButtonItem) {
        navigationItem.leftBarButtonItem = barButton
    }
    
    func configureMyAvatarManager() {
        guard let navController = navigationController else { return }
        myAvatarManager = MyAvatarManager(navigationController: navController, delegate: self)
        myAvatarManager?.setup()
    }
    
    func refreshMyAvatar() {
        myAvatarManager?.refreshMyAvatar()
    }
}

@available(iOS 14.0, *)
extension ChatRoomsListViewController :PushNotificationControlProtocol {
    func pushNotificationSettingsLoaded() {
        refreshContextMenuBarButton()
    }
}
