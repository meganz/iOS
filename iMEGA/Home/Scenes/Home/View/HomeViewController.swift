import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGAUIKit
import Search
import UIKit

@objc(HomeRouting)
protocol HomeRouting: NSObjectProtocol {

    func showAchievements()

    func showOfflines()
    func showOfflineFile(_ handle: String)

    func showRecents()
    
    func showFavourites()
    func showFavouritesNode(_ base64Handle: Base64HandleEntity)
}

final class HomeViewController: UIViewController, DisplayMenuDelegate {

    @objc var homeQuickActionSearch: Bool = false

    // MARK: - View Model
    
    var myAvatarViewModel: (any MyAvatarViewModelType)?

    var uploadViewModel: (any HomeUploadingViewModelType)?
    
    var startConversationViewModel: StartConversationViewModel?

    var recentsViewModel: (any HomeRecentActionViewModelType)?

    var bannerViewModel: (any HomeBannerViewModelType)?
    
    var viewModeStore: (any ViewModeStoringObjC)?

    var quickAccessWidgetViewModel: QuickAccessWidgetViewModel?
    
    var homeViewModel: HomeViewModel?
    
    // MARK: - Router

    var router: HomeRouter!

    // MARK: - IBOutlets

    @IBOutlet private weak var topStackView: UIStackView!

    @IBOutlet private weak var exploreView: ExploreViewStack!

    @IBOutlet private weak var bannerCollectionView: MEGABannerView!

    @IBOutlet private weak var slidePanelView: SlidePanelView!

    @IBOutlet weak var searchBarView: MEGASearchBarView!

    private weak var startConversationItem: UIBarButtonItem!

    private let startUploadBarButtonItem: UIBarButtonItem = UIBarButtonItem()

    private weak var badgeButton: BadgeButton!

    private var searchResultContainerView: UIView!
    
    private var newSearchEnabled = false

    // MARK: - SlidePanel Related Properties
    
    /// A layout constraint that make `SlidePanel` docking to `bottom` position.
    @IBOutlet var constraintToBottomPosition: NSLayoutConstraint!

    /// A layout constraint that make `SlidePanel` docking to `top` position.
    @IBOutlet var constraintToTopPosition: NSLayoutConstraint! {
        didSet {
            constraintToTopPosition.isActive = false
        }
    }
    
    // MARK: - Slide Panel

    private lazy var slidePanelAnimator: SlidePanelAnimationController = SlidePanelAnimationController(
        delegate: self
    )

    /// ContentViewController that has the content of `SlidePanel`
    private lazy var contentViewController: RecentsViewController = {
        let recentsViewController = UIStoryboard(name: "Recents", bundle: nil)
            .instantiateViewController(withIdentifier: "RecentsViewControllerID") as! RecentsViewController
        recentsViewController.delegate = self
        return recentsViewController
    }()
    
    private lazy var offlineViewController: OfflineViewController = {
        let offlineVC = UIStoryboard(name: "Offline", bundle: nil)
            .instantiateViewController(withIdentifier: "OfflineViewControllerID") as! OfflineViewController
        offlineVC.flavor = .HomeScreen
        return offlineVC
    }()

    var searchResultViewController: UIViewController!
    var searchResultsBridge: SearchResultsBridge!
    
    private var contextMenuManager: ContextMenuManager?

    // MARK: - ViewController Lifecycles
    private func currentViewMode() -> ViewModePreferenceEntity {
        viewModeStore!.viewMode(for: viewModeLocation)
    }
    
    private var viewModeLocation: ViewModeLocation_ObjWrapper {
        .init(customLocation: CustomViewModeLocation.HomeSearch)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        refreshView(with: traitCollection)
        setupViewModelEventListening()
        contextMenuManager = .init(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
        searchBarView.shouldShowContextButton = true
        
        if AudioPlayerManager.shared.isPlayerAlive() {
            let streamingInfoUseCase = StreamingInfoUseCase()
            streamingInfoUseCase.startServer()
        }
    }
    
    private func configureViewMode() {
        let currentViewMode = currentViewMode()
        
        updateContextMenuButtonMenu(viewMode: currentViewMode)
        
        if currentViewMode == .list {
            changeLayout(to: .list)
        } else if currentViewMode == .thumbnail {
            changeLayout(to: .thumbnail)
        }
    }
    
    private func updateContextMenuButtonMenu(viewMode: ViewModePreferenceEntity) {
        let config = CMConfigEntity(
            menuType: .menu(type: .home),
            viewMode: viewMode
        )
        let menu = contextMenuManager!.contextMenu(with: config)
        
        if let menu {
            searchBarView.setMenu(
                menu: menu
            )
        }
    }
    
    private func updateViewModeState(viewMode: ViewModePreferenceEntity) {
        if let layout = viewMode.pageLayout {
            changeLayout(to: layout)
        }
        viewModeStore?.save(viewMode: viewMode, forObjC: viewModeLocation)
        updateContextMenuButtonMenu(viewMode: viewMode)
    }
    
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .listView:
            updateViewModeState(viewMode: .list)
        case .thumbnailView:
            updateViewModeState(viewMode: .thumbnail)
        default:
            break
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        // not used in this screen
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if homeQuickActionSearch {
            homeQuickActionSearch = false
        }
        AudioPlayerManager.shared.addDelegate(self)
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
        configureViewMode()
        configureAdsVisibility()
        bannerCollectionView?.refreshContainer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerManager.shared.playerHiddenIgnoringPlayerLifeCycle(true, presenter: self)
    }

    private func setupViewModelEventListening() {
        myAvatarViewModel?.notifyUpdate = { [weak self] output in
            guard let self else { return }
            let resizedImage = output.avatarImage

            asyncOnMain {
                if let badgeButton = self.badgeButton {
                    badgeButton.setBadgeText(output.notificationNumber)
                    badgeButton.setAvatarImage(resizedImage)
                }
            }
        }
        myAvatarViewModel?.inputs.viewIsReady()

        recentsViewModel?.notifyUpdate = { [weak self] recentsViewModel in
            if let error = recentsViewModel.error {
                self?.handle(error)
            }
        }
        
        startConversationViewModel?.dispatch(.viewDidLoad)
        startConversationViewModel?.invokeCommand = { [weak self] command in
            asyncOnMain {
                switch command {
                case .networkAvailabilityUpdate(let networkAvailable):
                    self?.startConversationItem.isEnabled = networkAvailable
                }
            }
        }
        
        quickAccessWidgetViewModel?.invokeCommand = { [weak self] command in
            switch command {
            case .selectOfflineTab:
                self?.slidePanelView.showTab(.offline)
                
            case .selectRecentsTab:
                self?.slidePanelView.showTab(.recents)

            case .presentFavouritesNode(let base64Handle):
                self?.router.showNode(base64Handle)
                
            case .presentOfflineFileWithPath(let path):
                self?.navigationController?.popToRootViewController(animated: false)
                self?.offlineViewController.openFileFromWidget(with: path)
            case .showFavourites:
                self?.navigationController?.popToRootViewController(animated: false)
                self?.tappedCard(.favourites)
            }
        }
        quickAccessWidgetViewModel?.dispatch(.managePendingAction)

        uploadViewModel?.notifyUpdate = { [weak self] homeUploadingViewModel in
            asyncOnMain {
                guard let self else { return }
                self.startUploadBarButtonItem.isEnabled = homeUploadingViewModel.networkReachable

                switch homeUploadingViewModel.state {
                case .permissionDenied(let error): self.handle(error)
                case .normal: break
                }
                
                guard let contextMenu = homeUploadingViewModel.contextMenu else {
                    self.startUploadBarButtonItem.menu = nil
                    return
                }
            
                let uploadFileMenu = UIDeferredMenuElement.uncached { completion in
                    // Track tap on upload file button
                    self.homeViewModel?.didTapUploadFilesButton()
                    
                    completion(contextMenu.children)
                }
                self.startUploadBarButtonItem.menu = UIMenu(children: [uploadFileMenu])
            }
        }
        uploadViewModel?.inputs.viewIsReady()

        bannerViewModel?.notifyUpdate = { [weak self] bannerViewModelOutput in
            guard let self else { return }
            asyncOnMain {
                self.bannerCollectionView.reloadBanners(bannerViewModelOutput.state.banners)
                self.toggleBannerCollectionView(isOn: true)
            }
        }
        bannerViewModel?.inputs.viewIsReady()
        
        searchResultsBridge.hideKeyboardTrampoline = { [weak self] in
            self?.hideKeyboard()
        }
    }
    
    func changeLayout(to layout: PageLayout) {
        searchResultsBridge.didChangeLayoutTrampoline?(layout)
    }

    private func toggleBannerCollectionView(isOn: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.2, options: [], animations: {
            self.bannerCollectionView.isHidden = !isOn
        }, completion: { _ in
            if !RecentsPreferenceManager.showRecents() {
                NotificationCenter.default.post(name: NSNotification.Name.init(NSNotification.Name.MEGABannerChangedHomeHeight.rawValue), object: nil, userInfo: [NSNotification.Name.MEGAHomeChangedHeight.rawValue: isOn])
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        myAvatarViewModel?.inputs.viewIsAppearing()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        configureAdsVisibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSlidePanelVerticalOffset()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.bannerCollectionView?.refreshContainer()
        }, completion: nil)
    }

    private func setupSlidePanelVerticalOffset() {
        guard slidePanelAnimator.animationOffsetY == nil else { return }
        // Will only be executed once - the first time, and tell the `SlidePanelAnimator` that the **Vertical Offset**
        // between the top of slide panel and the top of `searchBarView`.
        slidePanelAnimator.animationOffsetY = (slidePanelView.frame.minY - searchBarView.frame.minY) + Constant.slidePanelRoundCornerHeight
    }

    private enum Constant {
        static let slidePanelRoundCornerHeight: CGFloat = 20 // This value need to be same as `constraintToTopPosition`
    }

    // MARK: - View Setup

    private func setupView() {
        setTitle(with: "MEGA")

        setupLeftItems()
        setupRightItems()
        setupSearchBarView(searchBarView)
        setupSearchResultExtendedLayout()
        setupBannerCollection()

        slidePanelView.delegate = self
        exploreView.delegate = self

        addContentViewController()
    }

    private func setTitle(with text: String) {
        navigationItem.title = text
        // Avoid using the title on pushing a view controller

        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: Strings.Localizable.home)
    }

    private func setupSearchResultExtendedLayout() {
        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true
    }

    private func setupLeftItems() {
        
        let badgeButton = BadgeButton()
        self.badgeButton = badgeButton
        badgeButton.addTarget(self, action: .didTapAvatar, for: .touchUpInside)
        
        let avatarButtonItem = UIBarButtonItem(customView: badgeButton)
        self.navigationItem.leftBarButtonItems = [avatarButtonItem]
        
    }
    
    private func setupRightItems() {
        let startConversationItem = UIBarButtonItem(
            image: UIImage.startChat,
            style: .plain,
            target: self,
            action: .didTapNewChat
        )
        startConversationItem.accessibilityLabel = Strings.Localizable.startConversation
        self.startConversationItem = startConversationItem
        
        startUploadBarButtonItem.image = UIImage.uploadFile
        
        startUploadBarButtonItem.accessibilityLabel = Strings.Localizable.upload

        navigationItem.setRightBarButtonItems([startUploadBarButtonItem, startConversationItem], animated: false)
    }
    
    private func setupSearchBarView(_ searchBarView: MEGASearchBarView) {
        searchBarView.delegate = self
        searchBarView.editingDelegate = searchResultsBridge
    }

    private func setupBannerCollection() {
        bannerCollectionView.isHidden = true
        bannerCollectionView.delegate = self
    }

    private func addContentViewController() {
        addChild(contentViewController)
        slidePanelView.addRecentsViewController(contentViewController)
        contentViewController.didUpdateMiniPlayerHeight = { [weak self] value in
            self?.searchResultsBridge.update(bottomInset: value)
        }
        contentViewController.didMove(toParent: self)
    }
    
    private func addOfflineViewController() {
        addChild(offlineViewController)
        slidePanelView.addOfflineViewController(offlineViewController)
        offlineViewController.didMove(toParent: self)
    }

    // MARK: - Refresh view with light/dark mode

    private func refreshView(with trait: UITraitCollection) {
        setupBackgroundColor(with: trait)
        setupNavigationBarColor(with: trait)
    }

    private func setupBackgroundColor(with trait: UITraitCollection) {
        let defaultColor = TokenColors.Background.page
        let darkColor = TokenColors.Background.page
        
        switch trait.theme {
        case .dark:
            slidePanelView.backgroundColor = darkColor
            view.backgroundColor = darkColor
        default:
            slidePanelView.backgroundColor = defaultColor
            view.backgroundColor = defaultColor
        }
    }

    private func setupNavigationBarColor(with trait: UITraitCollection) {
        let backgroundColor: UIColor
        switch trait.theme {
        case .light:
            backgroundColor = constraintToTopPosition.isActive ? UIColor.whiteFFFFFF : TokenColors.Background.surface1
            
        case .dark:
            backgroundColor = constraintToTopPosition.isActive ? UIColor.black1C1C1E :TokenColors.Text.primary
        }
        
        updateNavigationBarTitleColor(for: trait)
        updateNavigationBarBackgroundColor(backgroundColor)
    }

    // MARK: - Tap Actions

    @objc fileprivate func didTapAvatarItem() {
        router.didTap(on: .avatar)
    }

    @objc fileprivate func didTapNewChat() {
        // Track tap on new chat button
        homeViewModel?.didTapStartConversationButton()
        
        router.didTap(on: .newChat)
    }
    
    @objc func activateSearch() {
        _ = searchBarView?.becomeFirstResponder()
    }
    
    func hideKeyboard() {
        _ = searchBarView?.resignFirstResponder()
    }
}

// MARK: - SlidePanelAnimationControllerDelegate

extension HomeViewController: SlidePanelAnimationControllerDelegate {

    private func navigationBarTransitionColors(for trait: UITraitCollection) -> (UIColor, UIColor) {
        switch trait.userInterfaceStyle {
        case .dark:
            return (UIColor.black1C1C1E, TokenColors.Text.primary)
        default:
            return (UIColor.whiteFFFFFF, TokenColors.Background.surface1)
        }
    }
    
    private func updateNavigationBarTitleColor(for traitCollection: UITraitCollection) {
        guard let navigationBar = navigationController?.navigationBar else { return }
        AppearanceManager.forceNavigationBarTitleUpdate(navigationBar, traitCollection: traitCollection)
    }

    private func updateNavigationBarBackgroundColor(_ color: UIColor) {
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }

    func didUpdateAnimationProgress(
        _ animationProgress: CGFloat,
        from initialDockingPosition: SlidePanelAnimationController.DockingPosition,
        to targetDockingPosition: SlidePanelAnimationController.DockingPosition
    ) {
        let (slideColor, navigationBarColor) = navigationBarTransitionColors(for: self.traitCollection)
        let color: UIColor
        switch (initialDockingPosition, targetDockingPosition) {
        case (.top, .bottom):
            color = navigationBarColor
        case (.bottom, .top):
            let startColor = navigationBarColor
            let endColor = slideColor
            color = startColor.toColor(endColor, percentage: animationProgress * 100)
        default: fatalError("No other combinations")
        }
        updateNavigationBarBackgroundColor(color)
    }

    func animateToTopPosition() {
        self.constraintToBottomPosition.isActive = false
        self.constraintToTopPosition.isActive = true
        self.view.layoutIfNeeded()
        
        NotificationCenter.default.post(name: NSNotification.Name.init(NSNotification.Name.MEGAHomeChangedHeight.rawValue), object: nil, userInfo: [NSNotification.Name.MEGAHomeChangedHeight.rawValue: false])
    }

    func animateToBottomPosition() {
        self.constraintToBottomPosition.isActive = true
        self.constraintToTopPosition.isActive = false
        self.view.layoutIfNeeded()
        
        let notificationName = bannerCollectionView.isHidden ? NSNotification.Name.MEGAHomeChangedHeight.rawValue : NSNotification.Name.MEGABannerChangedHomeHeight.rawValue
        NotificationCenter.default.post(name: NSNotification.Name.init(notificationName), object: nil, userInfo: [notificationName: slidePanelAnimator.isInTopDockingPosition()])
    }
}

// MARK: - SlidePanelDelegate

extension HomeViewController: SlidePanelDelegate {

    func slidePanel(_ panel: SlidePanelView, didBeginPanningWithVelocity velocity: CGPoint) {
        slidePanelAnimator.startsProgressiveAnimation(withDuration: 0.3)
    }

    func slidePanel(_ panel: SlidePanelView, didStopPanningWithVelocity velocity: CGPoint) {
        slidePanelAnimator.completeAnimation(withVelocityY: velocity.y)
    }

    func slidePanel(_ panel: SlidePanelView, translated: CGPoint, velocity: CGPoint) {
        slidePanelAnimator.continueAnimation(withVelocityY: velocity.y, translationY: translated.y)
    }
    
    func shouldEnablePanGestureScrollingUp(inSlidePanel slidePanel: SlidePanelView) -> Bool {
        slidePanelAnimator.isInBottomDockingPosition()
    }
    
    func shouldEnablePanGestureScrollingDown(inSlidePanel slidePanel: SlidePanelView) -> Bool {
        slidePanelAnimator.isInTopDockingPosition() && slidePanelView.isOverScroll()
    }
    
    func shouldEnablePanGesture(inSlidePanel slidePanel: SlidePanelView) -> Bool {
        shouldEnablePanGestureScrollingDown(inSlidePanel: slidePanel) ||
            shouldEnablePanGestureScrollingDown(inSlidePanel: slidePanel)
    }
    
    func shouldEnablePanGestureInSlidePanel(_ panel: SlidePanelView, withVelocity velocity: CGPoint) -> Bool {
        let scrollUp = velocity.y < 0
        let scrollDown = velocity.y > 0
        
        if slidePanelAnimator.isInBottomDockingPosition() && scrollUp {
            return true
        }
        
        if slidePanelAnimator.isInTopDockingPosition() && scrollDown && slidePanelView.isOverScroll() {
            return true
        }
        return false
    }
    
    func offlineTabSelected(isFirstLoad: Bool) {
        if isFirstLoad {
            addOfflineViewController()
        } else {
            offlineViewController.reloadUI()
        }
    }
}

// MARK: - Explorer view delegate

extension HomeViewController: ExploreViewStackDelegate {
    func tappedCard(_ card: MEGAExploreViewStyle) {

        switch card {
        case .favourites:
            router.favouriteExplorerSelected()
        case .documents:
            router.documentsExplorerSelected()
        case .audio:
            router.audioExplorerSelected()
        case .video:
            router.videoExplorerSelected()
        }
    }
}

// MARK: - HomeRouting

extension HomeViewController: HomeRouting {
    func showAchievements() {
        router.didTap(on: .showAchievement)
    }

    func showOfflines() {
        quickAccessWidgetViewModel?.dispatch(.showOffline)
    }
    
    func showOfflineFile(_ handle: String) {
        quickAccessWidgetViewModel?.dispatch(.showOfflineFile(handle))
    }
    
    func showRecents() {
        quickAccessWidgetViewModel?.dispatch(.showRecents)
    }
    
    func showFavourites() {
        quickAccessWidgetViewModel?.dispatch(.showFavourites)
    }
    
    func showFavouritesNode(_ base64Handle: Base64HandleEntity) {
        quickAccessWidgetViewModel?.dispatch(.showFavouritesNode(base64Handle))
    }
}

// MARK: - RecentNodeActionDelegate

extension HomeViewController: RecentNodeActionDelegate, TextFileEditable {

    func showSelectedNode(in viewController: UIViewController?) {
        guard let controller = viewController else { return }
        navigationController?.present(controller, animated: true, completion: nil)
    }

    func showCustomActions(for node: MEGANode, fromSender sender: Any) {
        let selectionAction: (MEGANode, MegaNodeActionType) -> Void = { [router, weak self] node, action in
            guard let self else { return }
            switch action {
            
            // MARK: Text File
            case .editTextFile:
                router?.didTap(on: .editTextFile(node))
            case .viewVersions:
                router?.didTap(on: .viewTextFileVersions(node))
                
            // MARK: Info
            case .info:
                router?.didTap(on: .fileInfo(node))

            // MARK: Links
            case .manageLink, .shareLink:
                router?.didTap(on: .linkManagement(node))
            case .removeLink:
                router?.didTap(on: .removeLink(node))

            // MARK: Copy & Move & Delete
            case .moveToRubbishBin:
                router?.didTap(on: .delete(node))
            case .copy:
                router?.didTap(on: .copy(node))
            case .move:
                router?.didTap(on: .move(node))
            case .restore:
                node.mnz_restore()

            // MARK: Save && Download
            case .saveToPhotos:
                self.recentsViewModel?.inputs.saveToPhotoAlbum(of: node)
            case .download:
                router?.showDownloadTransfer(node: node)

            // MARK: Rename
            case .rename:
                node.mnz_renameNode(in: self)

            // MARK: Export File
            case .exportFile:
                router?.didTap(on: .exportFile(node, sender))
            case .shareFolder:
                self.homeViewModel?.openShareFolderDialog(forNode: node, router: router)
            case .manageShare:
                router?.didTap(on: .manageShare(node))
            case .leaveSharing:
                node.mnz_leaveSharing(in: self)

            // MARK: Send to chat
            case .sendToChat:
                node.mnz_sendToChat(in: self)

            // MARK: Favourite
            case .favourite:
                self.recentsViewModel?.inputs.toggleFavourite(of: node)

            case .label:
                self.router.didTap(on: .setLabel(node))
            case .hide:
                self.router.didTap(on: .hide(node))
            case .unhide:
                self.router.didTap(on: .unhide(node))
            default:
                break
            }
        }
        router.didTap(on: .nodeCustomActions(node), with: selectionAction)
    }
}

// MARK: - TraitEnvironmentAware

extension HomeViewController: TraitEnvironmentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        // Note: For Home page, we don't use `AppearanceManager.forceNavigationBarUpdate(_:traitCollection:)` to update its navigation bar
        // because Home page has special navigation bar color configuration driven by `SlidePanelView`
        refreshView(with: currentTrait)
    }
}

// MARK: - MEGASearchBarViewDelegate

extension HomeViewController: MEGASearchBarViewDelegate {

    func didStartSearchSessionOnSearchController(_ searchController: MEGASearchBarView) {
        homeViewModel?.didStartSearchSession()
        navigationController?.setNavigationBarHidden(true, animated: true)

        guard searchResultContainerView == nil else { return }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        searchResultContainerView = containerView

        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: searchBarView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        containerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        searchResultViewController.view.translatesAutoresizingMaskIntoConstraints = false
        searchResultViewController.willMove(toParent: self)
        addChild(searchResultViewController)
        containerView.wrap(searchResultViewController.view)
        searchResultViewController.didMove(toParent: self)
    }

    func didResumeSearchSessionOnSearchController(_ searchController: MEGASearchBarView) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func didFinishSearchSessionOnSearchController(_ searchController: MEGASearchBarView) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        searchResultViewController?.willMove(toParent: nil)
        searchResultContainerView?.constraints.deactivate()
        searchResultViewController?.view.removeFromSuperview()
        searchResultViewController?.removeFromParent()
        searchResultContainerView?.removeFromSuperview()
        searchResultContainerView = nil
        searchResultsBridge.didFinishSearching()
    }
}

// MARK: - MEGABannerViewDelegate

extension HomeViewController: MEGABannerViewDelegate {

    func didSelectMEGABanner(withBannerIdentifier bannerIdentifier: Int, actionURL: URL?) {
        bannerViewModel?.inputs.didSelectBanner(actionURL: actionURL)
    }

    func dismissMEGABanner(_ bannerView: MEGABannerView, withBannerIdentifier bannerIdentifier: Int) {
        bannerViewModel?.inputs.dismissBanner(withBannerId: bannerIdentifier)
    }

    func hideMEGABannerView(_ bannerView: MEGABannerView) {
        toggleBannerCollectionView(isOn: false)
    }
}

extension UIColor {
    func toColor(_ color: UIColor, percentage: CGFloat) -> UIColor {
        let percentage = max(min(percentage, 100), 0) / 100
        switch percentage {
        case 0: return self
        case 1: return color
        default:
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return self }
            guard color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }

            return UIColor(red: CGFloat(r1 + (r2 - r1) * percentage),
                           green: CGFloat(g1 + (g2 - g1) * percentage),
                           blue: CGFloat(b1 + (b2 - b1) * percentage),
                           alpha: CGFloat(a1 + (a2 - a1) * percentage))
        }
    }
}

// MARK: - Private Selector Extensions

private extension Selector {
    static let didTapAvatar = #selector(HomeViewController.didTapAvatarItem)
    static let didTapNewChat = #selector(HomeViewController.didTapNewChat)
}

// MARK: - AudioPlayer
extension HomeViewController: AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
}

// MARK: - Ads
extension HomeViewController: AdsSlotDisplayable {}

// MARK: - Page layout
extension ViewModePreferenceEntity {
    var pageLayout: PageLayout? {
        switch self {
        // only two of the viewModes can actually be mapped to page layout that
        // search results view support
        case .perFolder:
            return nil
        case .list:
            return .list
        case .thumbnail:
            return .thumbnail
        case .mediaDiscovery:
            return nil
        }
    }
}
