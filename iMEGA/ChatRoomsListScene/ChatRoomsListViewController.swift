import Combine
import MEGAChatSdk
import MEGAL10n
import MEGAUIKit
import SwiftUI

final class ChatRoomsListViewController: UIViewController {
    lazy var addBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.navigationbarAdd, style: .plain, target: nil, action: nil)
    
    lazy var moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private(set) var viewModel: ChatRoomsListViewModel

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: ChatRoomsListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureListView()
        updateTitleView()
        initSubscriptions()
        assignBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [moreBarButtonItem, addBarButtonItem]
        configureNavigationBarButtons(chatViewMode: viewModel.chatViewMode)
        viewModel.refreshMyAvatar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureAdsVisibility()
        
        AudioPlayerManager.shared.addDelegate(self)
        Task { @MainActor in
            await viewModel.askForNotificationsPermissionsIfNeeded()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureAdsVisibility()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #unavailable(iOS 18.0) {
            addBarButtonItem.menu = nil
            moreBarButtonItem.menu = nil
        }
        AudioPlayerManager.shared.playerHiddenIgnoringPlayerLifeCycle(true, presenter: self)
    }
    
    deinit {
        AudioPlayerManager.shared.removeDelegate(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureListView() {
        let hostingView = UIHostingController(rootView: ChatRoomsListView(viewModel: viewModel))
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingView.didMove(toParent: self)
    }
    
    private func updateTitleView() {
        if let statusString = viewModel.chatStatus?.localizedIdentifier {
            navigationItem.titleView = UILabel.customNavigationBarLabel(
                title: viewModel.title,
                subtitle: statusString,
                traitCollection: traitCollection
            )
        } else {
            navigationItem.title = viewModel.title
        }
    }
    
    private func initSubscriptions() {
        viewModel.refreshContextMenuBarButton = { [weak self] in self?.refreshContextMenuBarButton() }
        subscriptions = [
            viewModel.$chatViewMode.sink(receiveValue: { [weak self] chatViewMode in
                self?.configureNavigationBarButtons(chatViewMode: chatViewMode)
            }),
            viewModel.$chatStatus.sink(receiveValue: { [weak self] _ in
                self?.refreshContextMenuBarButton()
                self?.updateTitleView()
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
    
    // this function should be called in only 2 places :
    // 1. when view is created to have a default value
    // 2. whenever unread count changes (this is triggered by MainTabBarController
    // this should guarantee valid number shown in the back button and simplify the logic
    func assignBackButton() {
        let unreadChats = MEGAChatSdk.shared.unreadChats
        updateBackBarButtonItem(withUnreadMessages: unreadChats)
    }
    
    @objc func addBarButtonItemTapped() {
        viewModel.addChatButtonTapped()
    }
    
    private func updateBackBarButtonItem(withUnreadMessages count: Int) {
        guard count > 0 else {
            clearBackBarButtonItem()
            return
        }
        
        let title = String(format: "%td", count)
        assignBackButtonWith(title: title)
    }
    
    private func assignBackButtonWith(title: String?) {
        navigationItem.backBarButtonItem = BackBarButtonItem(
            title: title,
            menuTitle: Strings.Localizable.chat
        )
    }
    
    private func clearBackBarButtonItem() {
        assignBackButtonWith(title: nil)
    }
}

extension ChatRoomsListViewController: AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        Task { @MainActor in
            additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
        }
    }
}

// MARK: - Ads
extension ChatRoomsListViewController: AdsSlotDisplayable {}
