import MEGADomain
import MEGASDKRepo
import MEGAUIKit
import SwiftUI
import UIKit
import Video

final class VideoRevampTabContainerViewController: UIViewController {
    
    private let moreBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar, style: .plain, target: nil, action: nil)
    
    private lazy var cancelBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonItemTapped))
    }()
    
    private lazy var selectAllBarButtonItem = {
        UIBarButtonItem(image: UIImage.selectAllItems, style: .plain, target: self, action: #selector(selectAllBarButtonItemTapped))
    }()
    
    private var toolbar: UIViewController?
    
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
    
    private let viewModel: VideoRevampTabContainerViewModel
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(viewModel: VideoRevampTabContainerViewModel, fileSearchUseCase: some FilesSearchUseCaseProtocol, thumbnailUseCase: some ThumbnailUseCaseProtocol, videoConfig: VideoConfig, router: some VideoRevampRouting) {
        self.viewModel = viewModel
        self.fileSearchUseCase = fileSearchUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoConfig = videoConfig
        self.router = router
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
        
        toolbar = VideoRevampFactory.makeToolbarView(isDisabled: true, videoConfig: videoConfig)
        
        configureSearchBar()
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [moreBarButtonItem]
        setupContextMenuBarButton()
        
        if let navigationBar = navigationController?.navigationBar {
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        }
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeTabContainerView(
            fileSearchUseCase: fileSearchUseCase,
            thumbnailUseCase: thumbnailUseCase,
            syncModel: viewModel.syncModel,
            videoSelection: viewModel.videoSelection,
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
        guard let tabBarController, let toolbar else { return }
        
        toolbar.view.alpha = 0
        toolbar.view.translatesAutoresizingMaskIntoConstraints = false
        
        toolbar.view.backgroundColor = UIColor(videoConfig.colorAssets.toolbarBackgroundColor)
        
        tabBarController.view.addSubview(toolbar.view)
        NSLayoutConstraint.activate([
             toolbar.view.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
             toolbar.view.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor),
             toolbar.view.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor),
             toolbar.view.bottomAnchor.constraint(equalTo: tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        UIView.animate(withDuration: 0.33) {
            toolbar.view.alpha = 1.0
        }
    }
    
    private func hideToolbar() {
        UIView.animate(withDuration: 0.33, animations: { [weak self] in
            self?.toolbar?.view.alpha = 0.0
        }, completion: { [weak self] finished in
            if finished {
                self?.toolbar?.view.removeFromSuperview()
            }
        })
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
            refreshContextMenuBarButton()
        case .navigationBarCommand(.renderNavigationTitle(let title)):
            navigationItem.title = title
        case .searchBarCommand(.hideSearchBar):
            hideSearchBar()
        case .searchBarCommand(.reshowSearchBar):
            configureSearchBar()
        }
    }
    
    private func toggleEditing() {
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
        navigationItem.setRightBarButtonItems(isEditing ? [cancelBarButtonItem] : [moreBarButtonItem], animated: true)
    }
    
    @objc private func cancelBarButtonItemTapped() {
        setEditing(false, animated: true)
        setupNavigationBarButtons()
        viewModel.dispatch(.navigationBarAction(.didTapCancel))
    }
    
    @objc private func selectAllBarButtonItemTapped() {
        viewModel.dispatch(.navigationBarAction(.didTapSelectAll))
        
    }
    
    private func configureSearchBar() {
        if navigationItem.searchController == nil {
            navigationItem.searchController = searchController
        }
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar, traitCollection: traitCollection)
    }
    
    private func hideSearchBar() {
        searchController.searchBar.setShowsCancelButton(false, animated: true)
        navigationItem.searchController = nil
    }
}

// MARK: - TabContainerViewController+ContextMenu

extension VideoRevampTabContainerViewController {
    
    func setupContextMenuBarButton() {
        moreBarButtonItem.menu = contextMenuManager.contextMenu(with: contextMenuConfiguration())
    }
    
    private func refreshContextMenuBarButton() {
        setupContextMenuBarButton()
    }
    
    func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(
            menuType: .menu(type: .homeVideos),
            sortType: viewModel.syncModel.videoRevampSortOrderType,
            isVideosRevampExplorer: true,
            isSelectHidden: viewModel.isSelectHidden,
            isEmptyState: false
        )
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
}

// MARK: - TraitEnvironmentAware

extension VideoRevampTabContainerViewController: TraitEnvironmentAware {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar, traitCollection: traitCollection)
    }
}
