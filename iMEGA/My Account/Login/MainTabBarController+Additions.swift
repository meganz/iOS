import Accounts
import ChatRepo
import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAUIKit

let requestStatusProgressWindowManager = RequestStatusProgressWindowManager()

extension MainTabBarController {

    var isNavigationRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
    }

    func makeHomeViewController() -> UIViewController {
        HomeScreenFactory().createHomeScreen(
            from: self,
            tracker: DIContainer.tracker
        )
    }

    @objc func loadTabViewControllers() {
        let appTabs = TabManager.appTabs

        let viewControllers = appTabs.map {
            $0.viewController(from: self)
        }.compactMap { $0 }

        addTabDelegate()
        mainTabBarViewModel = createMainTabBarViewModel()
        mainTabBarAdsViewModel = MainTabBarAdsViewModel()
        configProgressView()
        showPSAViewIfNeeded()
        updateUI(with: viewControllers)
    }
    
    func makeCloudDriveViewController() -> UIViewController? {
        let config = NodeBrowserConfig(
            displayMode: .cloudDrive,
            adsConfiguratorProvider: {
                UIApplication.mainTabBarRootViewController() as? MainTabBarController
            }
        )
        
        return CloudDriveViewControllerFactory
            .make()
            .build(
                nodeSource: .node({ MEGASdk.shared.rootNode?.toNodeEntity() }),
                config: config
            )
    }

    func sharedItemsViewController() -> UIViewController? {
        guard let sharedItemsNavigationController = UIStoryboard(name: "SharedItems", bundle: nil).instantiateInitialViewController() as? MEGANavigationController else { return nil }
        sharedItemsNavigationController.navigationDelegate = self
        sharedItemsNavigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: MEGAAssets.UIImage.sharedItemsIcon,
            selectedImage: nil
        )
        return sharedItemsNavigationController
    }

    private func updateUI(with defaultViewControllers: [UIViewController]) {

        for i in 0..<defaultViewControllers.count {
            guard let navigationController = defaultViewControllers[i] as? MEGANavigationController else { break }
            navigationController.navigationDelegate = self

            guard
                let tabBarItem = navigationController.tabBarItem
            else { break }
            tabBarItem.accessibilityLabel = tabBarItem.title
        }

        viewControllers = defaultViewControllers

        setBadgeValueForSharedItemsIfNeeded()
        updateBadgeValueForChats()
        configurePhoneImageBadge()

        let selectedTabIndex = TabManager.indexOfTab(TabManager.selectedTab)
        selectedIndex = selectedTabIndex

        AppearanceManager.setupTabbar(tabBar)
    }

    @objc func configProgressView() {
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
    }

    @objc func configurePhoneImageBadge() {
        if phoneBadgeImageView == nil {
            phoneBadgeImageView = UIImageView(image: MEGAAssets.UIImage.phoneCallAll)
            phoneBadgeImageView?.tintColor = TokenColors.Indicator.green
            phoneBadgeImageView?.isHidden = true
            if let phoneBadgeImageView {
                tabBar.addSubview(phoneBadgeImageView)
            }
        }
    }
    
    func createMainTabBarViewModel() -> MainTabBarCallsViewModel {
        let router = MainTabBarCallsRouter(baseViewController: self)
        let mainTabBarCallsViewModel = MainTabBarCallsViewModel(
            router: router,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            callUpdateUseCase: CallUpdateUseCase(repository: CallUpdateRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatRoomUserUseCase: ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo, userStoreRepo: UserStoreRepository.newRepo),
            sessionUpdateUseCase: SessionUpdateUseCase(repository: SessionUpdateRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            handleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            callController: CallControllerProvider().provideCallController(), 
            callUpdateFactory: .defaultFactory,
            featureFlagProvider: DIContainer.featureFlagProvider,
            tracker: DIContainer.tracker
        )
        
        mainTabBarCallsViewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            executeCommand(command)
        }
        
        return mainTabBarCallsViewModel
    }

    private func executeCommand(_ command: MainTabBarCallsViewModel.Command) {
        switch command {
        case .showActiveCallIcon:
            updateBadgeValueForChats()
        case .hideActiveCallIcon:
            updateBadgeValueForChats()
        case .navigateToChatTab:
            selectedIndex = TabManager.chatTabIndex()
        }
    }
    
    private func trackEventForSelectedTabIndex() {
        switch selectedIndex {
        case TabManager.driveTabIndex():
            mainTabBarViewModel.dispatch(.didTapCloudDriveTab)
        case TabManager.chatTabIndex():
            mainTabBarViewModel.dispatch(.didTapChatRoomsTab)
        case TabManager.menuTabIndex():
            mainTabBarViewModel.dispatch(.didTapMenuTab)
        case TabManager.photosTabIndex():
            mainTabBarViewModel.dispatch(.didTapPhotosTab)
        case TabManager.homeTabIndex():
            mainTabBarViewModel.dispatch(.didTapHomeTab)
        default: break
        }
    }
    
    @objc func updateBadgeValueForChats() {
        let unreadChats = MEGAChatSdk.shared.unreadChats
        let numCalls = MEGAChatSdk.shared.numCalls

        if MEGAReachabilityManager.isReachable() && numCalls > 0,
           let callsInProgress = MEGAChatSdk.shared.chatCalls(withState: .inProgress)?.size,
           callsInProgress > 0 {
            updatePhoneImageBadgeFrame()
            phoneBadgeImageView?.isHidden = false
            setBadgeValueForChats(nil)
        } else {
            phoneBadgeImageView?.isHidden = true
            let unreadCountString = unreadChats > 99 ? "99+" : "\(unreadChats)"
            let badgeValue = unreadChats > 0 ? unreadCountString : nil
            setBadgeValueForChats(badgeValue)
        }
    }

    private func setBadgeValueForChats(_ badgeValue: String?) {
        if isNavigationRevampEnabled {
            let tabbarItem = tabBar.items?[TabManager.chatTabIndex()]
            tabbarItem?.badgeValue = badgeValue
        } else {
            tabBar.setBadge(
                value: badgeValue,
                color: TokenColors.Components.interactive,
                at: TabManager.chatTabIndex()
            )
        }
    }

    @objc func updatePhoneImageBadgeFrame() {
        // Need to wrap the code inside a Task in order for the code to work
        // in case of device orientation change. 
        Task { [self] in
            let chatTabIndex = TabManager.chatTabIndex()
            let tabBarButtons = tabBar.subviews
                .filter { type(of: $0) == NSClassFromString("UITabBarButton") }

            guard let button = tabBarButtons[safe: chatTabIndex] else { return }
            phoneBadgeImageView?.frame = frameForPhoneImageBadge(in: button)
        }
    }

    @objc func updateBadgeLayout(at index: Int) {
        guard !isNavigationRevampEnabled else { return }
        tabBar.updateBadgeLayout(at: index)
    }

    private func frameForPhoneImageBadge(in button: UIView) -> CGRect {
        let isRightToLeft = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        guard let iconView = button.subviews.first(where: { $0 is UIImageView }) else { return .null }
        let iconWidth = iconView.frame.size.width
        let iconViewframe = button.convert(iconView.frame, to: tabBar)
        let revampedBadgeSizeScale = 0.75
        let legacyBadgeSizeScale = 0.5

        let badgeSize = isNavigationRevampEnabled ? iconWidth * revampedBadgeSizeScale : iconWidth * legacyBadgeSizeScale
        let xOffset = (isNavigationRevampEnabled ? iconWidth * revampedBadgeSizeScale : iconWidth * 0.6) * (isRightToLeft ? -1 : 1)
        let yOffset = iconWidth * 0.25
        return .init(x: iconViewframe.origin.x + xOffset, y: iconViewframe.origin.y - yOffset, width: badgeSize, height: badgeSize)
    }

    @objc func showUploadFile() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.handleQuickUploadAction()
    }
    
    @objc func showScanDocument() {
        let cloudDriveTabIndex = TabManager.driveTabIndex()
        selectedIndex = cloudDriveTabIndex
        
        guard let navigationController = selectedViewController as? MEGANavigationController,
              let newCloudDriveViewController = navigationController.viewControllers.first as? NewCloudDriveViewController,
              let parentNode = newCloudDriveViewController.parentNode else {
            assertionFailure("Could not find NewCloudDriveViewController in tab bar at index: \(cloudDriveTabIndex)")
            return
        }
        
        let scanRouter = ScanDocumentViewRouter(presenter: newCloudDriveViewController, parent: parentNode)
        
        Task { @MainActor in
            await scanRouter.start()
        }
    }
    
    @objc func showCameraUploadsSettings() {
        guard let navController = children[safe: selectedIndex] as? MEGANavigationController else { return }
        let cuSettingsRouter = CameraUploadsSettingsViewRouter(
            presenter: navController,
            closure: { }
        )
        DeepLinkRouter(appNavigator: cuSettingsRouter).navigate()
    }
    
    @objc func addMEGAGlobalDelegate() {
        MEGASdk.shared.add(self)
    }
    
    @objc func handleApplicationWillEnterForeground() {
        guard let navController = selectedViewController as? MEGANavigationController,
              navController.viewControllers.last as? (any BottomOverlayPresenterProtocol) != nil else { return }
        
        showPSAViewIfNeeded()
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func addTabDelegate() {
        self.delegate = self
    }

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        showPSAViewIfNeeded()
        
        configureAdsVisibility()
        
        trackEventForSelectedTabIndex()
    }
}

// MARK: - MEGANavigationControllerDelegate
extension MainTabBarController: MEGANavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController!, willShow viewController: UIViewController!, animated: Bool) {
        updateBottomContainerVisibility(for: viewController)
    }
}

// MARK: - MEGAGlobalDelegate
extension MainTabBarController: MEGAGlobalDelegate {
    public func onEvent(_ api: MEGASdk, event: MEGAEvent) {
        if event.type == .reqStatProgress {
            if event.number == 0 {
                requestStatusProgressWindowManager.showProgressView(with: RequestStatusProgressViewModel(requestStatProgressUseCase: RequestStatProgressUseCase(repo: EventRepository.newRepo)))
            }
            
            if event.number == -1 {
                requestStatusProgressWindowManager.hideProgressView()
            }
        }
    }
    
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard !isNavigationRevampEnabled, let nodeList else { return }
        updateSharedItemsTabBadgeIfNeeded(nodeList)
    }
}
