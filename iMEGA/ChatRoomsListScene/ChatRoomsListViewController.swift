import SwiftUI
import Combine
import MEGAUIKit

@available(iOS 14.0, *)
final class ChatRoomsListViewController: UIViewController {

    lazy var addBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image, style: .plain, target: nil, action: nil)
    
    lazy var moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: nil, action: nil)
    
    private(set) var viewModel: ChatRoomsListViewModel
    private let notificationCenter: NotificationCenter

    private var subscriptions = Set<AnyCancellable>()

    lazy var hostingView = UIHostingController(rootView: ChatRoomsListView(viewModel:  viewModel))

    init(viewModel: ChatRoomsListViewModel,
         notificationCenter: NotificationCenter = NotificationCenter.default
    ) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureListView()
        updateTitleView()
        initSubscriptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [moreBarButtonItem, addBarButtonItem]
        configureNavigationBarButtons(chatMode: viewModel.chatMode)
        viewModel.refreshMyAvatar()
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
            }),
            notificationCenter
                .publisher(for: .chatDoNotDisturbUpdate)
                .sink(receiveValue: { [weak self] _ in
                    self?.refreshContextMenuBarButton()
                }),
            viewModel.$myAvatarBarButton.sink(receiveValue: { [weak self] myAvatarBarButton in
                self?.navigationItem.leftBarButtonItem = myAvatarBarButton
            }),
            viewModel.$isConnectedToNetwork.sink(receiveValue: { [weak self] isConnectedToNetwork in
                self?.addBarButtonItem.isEnabled = isConnectedToNetwork
                self?.updateTitleView()
            })
        ]
    }
    
    @objc func addBarButtonItemTapped() {
        viewModel.addChatButtonTapped()
    }
}
