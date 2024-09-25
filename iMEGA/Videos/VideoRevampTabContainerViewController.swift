import Combine
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import MEGAUIKit
import SwiftUI
import UIKit
import Video

final class VideoRevampTabContainerViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var recentlyWatchedVideosBarButtonItem = {
        UIBarButtonItem(image: UIImage.clockPlay, style: .plain, target: self, action: #selector(recentlyWatchedVideosButtonItemTapped))
    }()
    private let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private lazy var cancelBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonItemTapped))
    }()
    
    private lazy var selectAllBarButtonItem = {
        UIBarButtonItem(image: UIImage.selectAllItems, style: .plain, target: self, action: #selector(selectAllBarButtonItemTapped))
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
    
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    private let viewModel: VideoRevampTabContainerViewModel
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let videoPlaylistUseCase: any VideoPlaylistUseCaseProtocol
    private let videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    private let videoPlaylistModificationUseCase: any VideoPlaylistModificationUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol

    private let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private let videoToolbarViewModel: VideoToolbarViewModel
    
    private var showSnackBarSubscription: AnyCancellable?
    
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
        videoConfig: VideoConfig,
        router: some VideoRevampRouting,
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
        self.videoConfig = videoConfig
        self.router = router
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancellables.removeAll()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = defaultRightBarButtonItems()
        setupContextMenuBarButton(currentTab: viewModel.syncModel.currentTab)
        
        if let navigationBar = navigationController?.navigationBar {
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
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
            videoConfig: videoConfig,
            router: router
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
        } else {
            hideToolbar()
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
        toolbar.items = [
            UIBarButtonItem(image: videoConfig.toolbarAssets.offlineImage, style: .plain, target: self, action: #selector(downloadAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.linkImage, style: .plain, target: self, action: #selector(linkAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.saveToPhotosImage, style: .plain, target: self, action: #selector(saveToPhotosAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.sendToChatImage, style: .plain, target: self, action: #selector(sendToChatAction(_:))),
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: videoConfig.toolbarAssets.moreListImage, style: .plain, target: self, action: #selector(moreAction(_:)))
        ]
    }
    
    private func configureToolbarAppearance() {
        videoToolbarViewModel.$isDisabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDisabled in
                self?.toolbar.items?.forEach { $0.isEnabled = !isDisabled }
            }
            .store(in: &cancellables)
        
        toolbar.items?.forEach { $0.tintColor = UIColor(videoConfig.colorAssets.primaryIconColor) }
        toolbar.backgroundColor = UIColor(videoConfig.colorAssets.toolbarBackgroundColor)
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
    
    private func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
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
        navigationItem.setRightBarButtonItems(isEditing ? [cancelBarButtonItem] : defaultRightBarButtonItems(), animated: true)
    }
    
    private func defaultRightBarButtonItems() -> [UIBarButtonItem] {
        featureFlagProvider.isFeatureFlagEnabled(for: .recentlyWatchedVideos)
        ? [moreBarButtonItem, recentlyWatchedVideosBarButtonItem]
        : [moreBarButtonItem]
    }
    
    @objc private func cancelBarButtonItemTapped() {
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
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar,
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                               traitCollection: traitCollection)
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
        let searchText = searchController.searchBar.text?.trim ?? ""
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
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar,
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                               traitCollection: traitCollection)
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
