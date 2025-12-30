import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPreference
import MEGASwiftUI
import MEGAUIKit
import SwiftUI
import UIKit
import Video

final class VideoRevampTabContainerViewController: UIViewController {
    let router: any VideoRevampRouting
    let tracker: any AnalyticsTracking
    
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: VideoRevampTabContainerViewModel
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let videoPlaylistUseCase: any VideoPlaylistUseCaseProtocol
    private let videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    private let videoConfig: VideoConfig
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let videoToolbarViewModel: VideoToolbarViewModel
    private var showSnackBarSubscription: AnyCancellable?
    
    private lazy var recentlyWatchedVideosBarButtonItem = {
        UIBarButtonItem(image: MEGAAssets.UIImage.clockPlay, style: .plain, target: self, action: #selector(recentlyWatchedVideosButtonItemTapped))
    }()
    private let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private lazy var cancelBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonItemTapped))
    }()
    
    private lazy var selectAllBarButtonItem = {
        UIBarButtonItem(image: MEGAAssets.UIImage.selectAllItems, style: .plain, target: self, action: #selector(selectAllBarButtonItemTapped))
    }()
    
    private var toolbar = UIToolbar()
    
    private lazy var contextMenuManager = ContextMenuManager(
        displayMenuDelegate: self,
        createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
    )
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.searchBar.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        return controller
    }()
    
    init(
        viewModel: VideoRevampTabContainerViewModel,
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        videoPlaylistUseCase: some VideoPlaylistUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.viewModel = viewModel
        self.fileSearchUseCase = fileSearchUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.videoPlaylistUseCase = videoPlaylistUseCase
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.videoPlaylistModificationUseCase = videoPlaylistModificationUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.videoConfig = videoConfig
        self.router = router
        self.tracker = tracker
        self.videoToolbarViewModel = VideoToolbarViewModel()
        self.featureFlagProvider = featureFlagProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupContentView()
        viewModel.dispatch(.onViewDidLoad)
        setupNavigationBar()
        configureSearchBar()
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetsTraitOverridesIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        subscribeToCurrentTabChanged()
        configureToolbarAppearance()
        subscribeToVideoSelection()
        listenToSnackBarPresentation()
        subscribeToEditMode()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancellables.removeAll()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = defaultRightBarButtonItems()
        setupContextMenuBarButton(currentTab: viewModel.syncModel.currentTab)

        if let navigationBar = navigationController?.navigationBar {
            AppearanceManager.forceNavigationBarUpdate(navigationBar)
        }
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeTabContainerView(
            fileSearchUseCase: fileSearchUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            syncModel: viewModel.syncModel,
            videoSelection: viewModel.videoSelection,
            videoPlaylistUseCase: videoPlaylistUseCase,
            videoPlaylistContentUseCase: videoPlaylistContentUseCase,
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            nodeIconUseCase: nodeIconUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            videoConfig: videoConfig,
            router: router,
            featureFlagProvider: DIContainer.featureFlagProvider
        )
        add(contentView, container: view, animate: false)
        
        view.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        setupToolbar(editing: editing)
    }
    
    private func setupToolbar(editing: Bool) {
        if editing {
            showToolbar()
            hideMainTabBar()
        } else {
            hideToolbar()
            showMainTabBar()
        }
    }
    
    private func showMainTabBar() {
        UIView.animate(withDuration: 0.1) {
            self.tabBarController?.tabBar.alpha = 1
        }
    }
    
    private func hideMainTabBar() {
        UIView.animate(withDuration: 0.1) {
            self.tabBarController?.tabBar.alpha = 0
        }
    }
    
    private func showToolbar() {
        toolbar.alpha = 0
        configureToolbar()
        
        tabBarController?.view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        if let tabBar = tabBarController?.tabBar {
            NSLayoutConstraint.activate([
                toolbar.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 0),
                toolbar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 0),
                toolbar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: 0),
                toolbar.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor, constant: 0)
            ])
        }
        
        UIView.animate(
            withDuration: 0.33,
            animations: { [weak self] in
                self?.toolbar.alpha = 1
            }
        )
    }
    
    private func configureToolbar() {
        if #available(iOS 26.0, *), featureFlagProvider.isLiquidGlassEnabled() {
            configureToolbarWithGroups()
        } else {
            configureToolbarLegacy()
        }
    }
    
    @available(iOS 26.0, *)
    private func configureToolbarWithGroups() {
        let leftGroup = UIBarButtonItemGroup(
            barButtonItems: [
                UIBarButtonItem(image: videoConfig.toolbarAssets.offlineImage, style: .plain, target: self, action: #selector(downloadAction(_:)))
            ],
            representativeItem: nil
        )
        
        let centerGroup = UIBarButtonItemGroup(
            barButtonItems: [
                UIBarButtonItem(image: videoConfig.toolbarAssets.linkImage, style: .plain, target: self, action: #selector(linkAction(_:))),
                UIBarButtonItem(image: videoConfig.toolbarAssets.saveToPhotosImage, style: .plain, target: self, action: #selector(saveToPhotosAction(_:))),
                UIBarButtonItem(image: videoConfig.toolbarAssets.sendToChatImage, style: .plain, target: self, action: #selector(sendToChatAction(_:)))
            ],
            representativeItem: nil
        )
        
        let rightGroup = UIBarButtonItemGroup(
            barButtonItems: [
                UIBarButtonItem(image: videoConfig.toolbarAssets.moreListImage, style: .plain, target: self, action: #selector(moreAction(_:)))
            ],
            representativeItem: nil
        )
        
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: createGroupView(leftGroup)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: createGroupView(centerGroup)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: createGroupView(rightGroup)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
    }
    
    private func configureToolbarLegacy() {
        let downloadItem = UIBarButtonItem(image: videoConfig.toolbarAssets.offlineImage, style: .plain, target: self, action: #selector(downloadAction(_:)))
        let linkItem = UIBarButtonItem(image: videoConfig.toolbarAssets.linkImage, style: .plain, target: self, action: #selector(linkAction(_:)))
        let saveToPhotosItem = UIBarButtonItem(image: videoConfig.toolbarAssets.saveToPhotosImage, style: .plain, target: self, action: #selector(saveToPhotosAction(_:)))
        let sendToChatItem = UIBarButtonItem(image: videoConfig.toolbarAssets.sendToChatImage, style: .plain, target: self, action: #selector(sendToChatAction(_:)))
        let moreItem = UIBarButtonItem(image: videoConfig.toolbarAssets.moreListImage, style: .plain, target: self, action: #selector(moreAction(_:)))
        
        let flexibleSpace = UIBarButtonItem.flexibleSpace()
        
        toolbar.items = [
            downloadItem,
            flexibleSpace,
            linkItem,
            flexibleSpace,
            saveToPhotosItem,
            flexibleSpace,
            sendToChatItem,
            flexibleSpace,
            moreItem
        ]
    }
    
    private func createGroupView(_ group: UIBarButtonItemGroup) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        
        for item in group.barButtonItems {
            if let button = item.customView as? UIButton ?? createButton(from: item) {
                stackView.addArrangedSubview(button)
            }
        }
        
        return stackView
    }
    
    private func createButton(from barButtonItem: UIBarButtonItem) -> UIButton? {
        guard let image = barButtonItem.image,
              let action = barButtonItem.action,
              let target = barButtonItem.target else {
            return nil
        }
        
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.tintColor = UIColor(videoConfig.colorAssets.primaryIconColor)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return button
    }
    
    private func configureToolbarAppearance() {
        videoToolbarViewModel.$isDisabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDisabled in
                self?.toolbar.items?.forEach { $0.isEnabled = !isDisabled }
            }
            .store(in: &cancellables)
        
        if #available(iOS 26.0, *), featureFlagProvider.isLiquidGlassEnabled() {
            let appearance = UIToolbarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
            appearance.backgroundColor = UIColor(videoConfig.colorAssets.toolbarBackgroundColor).withAlphaComponent(0.8)
            
            toolbar.isTranslucent = true
            toolbar.standardAppearance = appearance
            toolbar.compactAppearance = appearance
            toolbar.scrollEdgeAppearance = appearance
        } else {
            toolbar.isTranslucent = false
            toolbar.backgroundColor = UIColor(videoConfig.colorAssets.toolbarBackgroundColor)
        }
        
        toolbar.items?.forEach { $0.tintColor = UIColor(videoConfig.colorAssets.primaryIconColor) }
    }
    
    private func hideToolbar() {
        UIView.animate(
            withDuration: 0.33,
            animations: { [weak self] in
                self?.toolbar.alpha = 0
            },
            completion: {  [weak self] _ in
                self?.toolbar.removeFromSuperview()
            }
        )
    }
    
    private func setupBindings() {
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
    }
    
    @MainActor
    private func executeCommand(_ command: VideoRevampTabContainerViewModel.Command) {
        switch command {
        case .navigationBarCommand(.toggleEditing):
            toggleEditing()
        case .navigationBarCommand(.refreshContextMenu):
            refreshContextMenuBarButton(currentTab: viewModel.syncModel.currentTab)
        case .navigationBarCommand(.renderNavigationTitle(let title)):
            navigationItem.title = title
        case .searchBarCommand(.hideSearchBar):
            hideSearchBar()
        case .searchBarCommand(.reshowSearchBar):
            configureSearchBar()
        }
    }
    
    func toggleEditing() {
        setEditing(!isEditing, animated: true)
        setupNavigationBarButtons()
    }
    
    private func setupNavigationBarButtons() {
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()
    }
    
    private func setupLeftNavigationBarButtons() {
        navigationItem.setLeftBarButtonItems(isEditing ? [selectAllBarButtonItem] : nil, animated: true)
    }
    
    private func setupRightNavigationBarButtons() {
        if !DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) {
            navigationItem.setRightBarButtonItems(isEditing ? [cancelBarButtonItem] : defaultRightBarButtonItems(), animated: true)
        } else if isEditing {
            navigationItem.setRightBarButtonItems([cancelBarButtonItem], animated: true)
        }
    }
    
    private func defaultRightBarButtonItems() -> [UIBarButtonItem] {
        featureFlagProvider.isFeatureFlagEnabled(for: .recentlyWatchedVideos)
        ? [moreBarButtonItem, recentlyWatchedVideosBarButtonItem]
        : [moreBarButtonItem]
    }
    
    @objc private func cancelBarButtonItemTapped() {
        viewModel.syncModel.searchText.removeAll()
        resetNavigationBar()
    }
    
    @objc private func selectAllBarButtonItemTapped() {
        viewModel.dispatch(.navigationBarAction(.didTapSelectAll))
    }
    
    @objc private func recentlyWatchedVideosButtonItemTapped() {
        router.openRecentlyWatchedVideos()
    }
    
    private func configureSearchBar() {
        if navigationItem.searchController == nil {
            navigationItem.searchController = searchController
        }
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar)
    }
    
    private func hideSearchBar() {
        searchController.searchBar.setShowsCancelButton(false, animated: true)
        navigationItem.searchController = nil
    }
    
    private func subscribeToCurrentTabChanged() {
        viewModel.syncModel.$currentTab
            .sink { [weak self] in self?.refreshContextMenuBarButton(currentTab: $0) }
            .store(in: &cancellables)
    }
    
    private func subscribeToEditMode() {
        viewModel.syncModel.$editMode
            .sink { [weak self] editMode in
                guard let self, isEditing != editMode.isEditing else { return }
                enterEditingMode()
            }
            .store(in: &cancellables)
    }
    
    private func enterEditingMode() {
        guard !isEditing else { return }
        
        executeCommand(.navigationBarCommand(.toggleEditing))
        executeCommand(.searchBarCommand(.hideSearchBar))
        
        setupNavigationBarButtons()
    }
    
    private func subscribeToVideoSelection() {
        Publishers.CombineLatest(
            viewModel.videoSelection.$editMode.map(\.isEditing),
            viewModel.videoSelection.$videos.map(\.isNotEmpty)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (isEditing, hasSelectedItem) in
            if isEditing {
                self?.videoToolbarViewModel.isDisabled = !hasSelectedItem
            } else {
                self?.videoToolbarViewModel.isDisabled = true
            }
        }
        .store(in: &cancellables)
    }
    
    @objc private func downloadAction(_ sender: UIBarButtonItem) {
        switch viewModel.syncModel.currentTab {
        case .all:
            let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
            nodeAction(nodeActionViewController, didSelect: .download, forNodes: selectedVideos, from: sender)
        case .playlist:
            break
        }
    }
    
    @objc private func linkAction(_ sender: UIBarButtonItem) {
        switch viewModel.syncModel.currentTab {
        case .all:
            let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
            nodeAction(nodeActionViewController, didSelect: .manageLink, forNodes: selectedVideos, from: sender)
        case .playlist:
            break
        }
    }
    
    @objc private func saveToPhotosAction(_ sender: UIBarButtonItem) {
        switch viewModel.syncModel.currentTab {
        case .all:
            let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
            nodeAction(nodeActionViewController, didSelect: .saveToPhotos, forNodes: selectedVideos, from: sender)
        case .playlist:
            break
        }
    }
    
    @objc private func sendToChatAction(_ sender: UIBarButtonItem) {
        switch viewModel.syncModel.currentTab {
        case .all:
            let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
            nodeAction(nodeActionViewController, didSelect: .sendToChat, forNodes: selectedVideos, from: sender)
        case .playlist:
            break
        }
    }
    
    @objc private func moreAction(_ sender: UIBarButtonItem) {
        switch viewModel.syncModel.currentTab {
        case .all:
            let nodeActionViewController = nodeActionViewController(with: selectedVideos, from: sender)
            present(nodeActionViewController, animated: true, completion: nil)
        case .playlist:
            break
        }
    }
    
    private func nodeActionViewController(with selectedVideos: [MEGANode], from sender: UIBarButtonItem) -> NodeActionViewController {
        let viewController = NodeActionViewController(
            nodes: selectedVideos, delegate: self, displayMode: .cloudDrive, sender: sender)
        viewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        return viewController
    }
    
    private var selectedVideos: [MEGANode] {
        viewModel.videoSelection.videos.values
            .map { $0 }
            .compactMap { $0.toMEGANode(in: .sharedSdk) }
    }
    
    func resetNavigationBar() {
        setEditing(false, animated: true)
        setupNavigationBarButtons()
        viewModel.dispatch(.navigationBarAction(.didTapCancel))
    }
}

// MARK: - TabContainerViewController+ContextMenu

extension VideoRevampTabContainerViewController {
    
    func setupContextMenuBarButton(currentTab: VideosTab) {
        moreBarButtonItem.menu = contextMenuManager.contextMenu(with: contextMenuConfiguration(currentTab: currentTab))
    }
    
    private func refreshContextMenuBarButton(currentTab: VideosTab) {
        setupContextMenuBarButton(currentTab: currentTab)
    }
    
    func contextMenuConfiguration(currentTab: VideosTab) -> CMConfigEntity {
        switch currentTab {
        case .all:
            CMConfigEntity(
                menuType: .menu(type: .homeVideos),
                sortType: viewModel.syncModel.videoRevampSortOrderType,
                isVideosRevampExplorer: true,
                isSelectHidden: viewModel.isSelectHidden,
                isEmptyState: false
            )
        case .playlist:
            CMConfigEntity(
                menuType: .menu(type: .homeVideoPlaylists),
                sortType: viewModel.syncModel.videoRevampVideoPlaylistsSortOrderType,
                isVideosRevampExplorerVideoPlaylists: true,
                isFilterEnabled: false,
                isSelectHidden: true
            )
        }
    }
}

// MARK: - TabContainerViewController+DisplayMenuDelegate

extension VideoRevampTabContainerViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        viewModel.dispatch(.navigationBarAction(.didReceivedDisplayMenuAction(action: action)))
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        viewModel.dispatch(.navigationBarAction(.didSelectSortMenuAction(sortType: sortType)))
    }
}

// MARK: - UISearchResultsUpdating

extension VideoRevampTabContainerViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController === self.navigationItem.searchController else { return }
        let searchText = searchController.searchBar.text ?? ""
        viewModel.dispatch(.searchBarAction(.updateSearchResults(searchText: searchText)))
    }
}

// MARK: - UISearchBarDelegate

extension VideoRevampTabContainerViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        viewModel.dispatch(.searchBarAction(.cancel))
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        viewModel.dispatch(.searchBarAction(.becomeActive))
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.dispatch(.searchBarAction(.searchBarTextDidEndEditing))
    }
}

// MARK: - TraitEnvironmentAware

extension VideoRevampTabContainerViewController: TraitEnvironmentAware {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar)
    }
}

// MARK: - BrowserViewControllerDelegate

extension VideoRevampTabContainerViewController: BrowserViewControllerDelegate {
    
    public func nodeEditCompleted(_ complete: Bool) {
        resetNavigationBar()
    }
}

extension VideoRevampTabContainerViewController {
    
    private func listenToSnackBarPresentation() {
        viewModel.syncModel.$shouldShowSnackBar
            .filter { $0 == true }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let snackBar = SnackBar(message: viewModel.syncModel.snackBarMessage)
                showSnackBar(snackBar: snackBar)
            }
            .store(in: &cancellables)
    }
}
