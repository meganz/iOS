import Accounts
import ChatRepo
import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAUIKit

let requestStatusProgressWindowManager = RequestStatusProgressWindowManager()

extension MainTabBarController {
    @objc func makeHomeViewController() -> UIViewController {
        HomeScreenFactory().createHomeScreen(
            from: self,
            tracker: DIContainer.tracker
        )
    }

    @objc func loadTabViewControllers() {
        defaultViewControllers = .init(capacity: 5)

        if let cloudDriveVC = makeCloudDriveViewController() {
            defaultViewControllers.add(cloudDriveVC)
        }
        if let photoAlbumVC = photoAlbumViewController() {
            defaultViewControllers.add(photoAlbumVC)
        }

        defaultViewControllers.add(makeHomeViewController())
        defaultViewControllers.add(chatViewController())

        if let sharedItemsVC = sharedItemsViewController() {
            defaultViewControllers.add(sharedItemsVC)
        }

        addTabDelegate()
        mainTabBarViewModel = createMainTabBarViewModel()
        mainTabBarAdsViewModel = MainTabBarAdsViewModel()
        configProgressView()
        showPSAViewIfNeeded()
        updateUI()
    }
    
    private func makeCloudDriveViewController() -> UIViewController? {
        let config = NodeBrowserConfig(
            displayMode: .cloudDrive,
            showsAvatar: true,
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
    
    @objc func showPSAViewIfNeeded() {
        if psaViewModel == nil {
            psaViewModel = createPSAViewModel()
        }
        guard let psaViewModel else { return }
        showPSAViewIfNeeded(psaViewModel)
    }

    @objc func sharedItemsViewController() -> UIViewController? {
        guard let sharedItemsNavigationController = UIStoryboard(name: "SharedItems", bundle: nil).instantiateInitialViewController() as? MEGANavigationController,
              let vc = sharedItemsNavigationController.viewControllers.first
        else { return nil }
        (vc as? (any MyAvatarPresenterProtocol))?.configureMyAvatarManager()
        sharedItemsNavigationController.navigationDelegate = self
        return sharedItemsNavigationController
    }

    @objc func updateUI() {
        guard let defaultViewControllers = defaultViewControllers as? [UIViewController] else { return }

        for i in  0...defaultViewControllers.count-1 {
            guard let navigationController = defaultViewControllers[i] as? MEGANavigationController else { break }
            navigationController.navigationDelegate = self

            guard
                let tabBarItem = navigationController.tabBarItem,
                let tabType = TabType(rawValue: i)
            else { break }
            tabBarItem.title = nil
            reloadInsets(for: tabBarItem)
            tabBarItem.accessibilityLabel = Tab(tabType: tabType).title
        }
        
        viewControllers = defaultViewControllers

        setBadgeValueForSharedItems()
        setBadgeValueForChats()
        configurePhoneImageBadge()

        selectedViewController = defaultViewControllers[TabManager.getPreferenceTab().tabType.rawValue]

        AppearanceManager.setupTabbar(tabBar)
    }

    @objc func configProgressView() {
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
    }

    @objc func reloadInsets(for tabBarItem: UITabBarItem) {
        if traitCollection.horizontalSizeClass == .regular {
            tabBarItem.imageInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            tabBarItem.imageInsets = .init(top: 6, left: 0, bottom: -6, right: 0)
        }
    }

    @objc func configurePhoneImageBadge() {
        if phoneBadgeImageView == nil {
            phoneBadgeImageView = UIImageView(image: .init(named: "onACall"))
            phoneBadgeImageView?.isHidden = true
            if let phoneBadgeImageView {
                tabBar.addSubview(phoneBadgeImageView)
            }
        }
    }

    @objc func createPSAViewModel() -> PSAViewModel? {
        let router = PSAViewRouter(tabBarController: self)
        let useCase = PSAUseCase(repo: PSARepository.newRepo)
        return PSAViewModel(router: router, useCase: useCase)
    }
    
    @objc func showPSAViewIfNeeded(_ psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.showPSAViewIfNeeded)
    }
    
    @objc func hidePSAView(_ hide: Bool, psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.setPSAViewHidden(hide))
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
            phoneBadgeImageView?.isHidden = unreadMessages > 0
        case .hideActiveCallIcon:
            phoneBadgeImageView?.isHidden = true
        case .navigateToChatTab:
            selectedIndex = TabType.chat.rawValue
        }
    }
    
    private func trackEventForSelectedTabIndex() {
        switch selectedIndex {
        case TabType.cloudDrive.rawValue:
            mainTabBarViewModel.dispatch(.didTapCloudDriveTab)
        case TabType.chat.rawValue:
            mainTabBarViewModel.dispatch(.didTapChatRoomsTab)
        default: break
        }
    }
    
    @objc func setBadgeValueForChats() {
        let unreadChats = MEGAChatSdk.shared.unreadChats
        let numCalls = MEGAChatSdk.shared.numCalls
        
        unreadMessages = unreadChats
        
        if MEGAReachabilityManager.isReachable() && numCalls > 0 {
            let callsInProgress = MEGAChatSdk.shared.chatCalls(withState: .inProgress)?.size ?? 0
            let shouldHidePhoneBadge = !(callsInProgress > 0) || unreadChats > 0
            phoneBadgeImageView?.isHidden = shouldHidePhoneBadge
        } else {
            phoneBadgeImageView?.isHidden = true
        }
        
        let unreadCountString = unreadChats > 99 ? "99+" : "\(unreadChats)"
        let badgeValue = unreadChats > 0 ? unreadCountString : nil
        tabBar.setBadge(
            value: badgeValue,
            color: TokenColors.Components.interactive,
            at: TabType.chat.rawValue
        )
    }
    
    @objc func showUploadFile() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.handleQuickUploadAction()
    }
    
    @objc func showScanDocument() {
        let cloudDriveTabIndex = TabType.cloudDrive.rawValue
        selectedIndex = cloudDriveTabIndex
        
        guard let navigationController = children[safe: cloudDriveTabIndex] as? MEGANavigationController,
              let newCloudDriveViewController = navigationController.viewControllers.first as? NewCloudDriveViewController,
              let parentNode = newCloudDriveViewController.parentNode else {
            assertionFailure("The first tabbar VC must be a NewCloudDriveViewController")
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
}
