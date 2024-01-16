import MEGADomain
import MEGAL10n
import MEGASDKRepo
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
    
    private let viewModel: VideoRevampTabContainerViewModel
    private let videoConfig: VideoConfig
    
    init(viewModel: VideoRevampTabContainerViewModel, videoConfig: VideoConfig) {
        self.viewModel = viewModel
        self.videoConfig = videoConfig
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupContentView()
        setupBindings()
        
        toolbar = VideoRevampFactory.makeToolbarView(isDisabled: true, videoConfig: videoConfig)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [moreBarButtonItem]
        setupNavigationItemTitle()
        setupContextMenuBarButton()
        
        if let navigationBar = navigationController?.navigationBar {
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        }
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeTabContainerView(videoConfig: videoConfig)
        add(contentView, container: view, animate: false)
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
        
        toolbar.view.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        
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
        setupNavigationItemTitle()
    }
    
    private func setupNavigationItemTitle() {
        navigationItem.title = isEditing ? Strings.Localizable.selectTitle : Strings.Localizable.Videos.Navigationbar.title
    }
    
    @objc private func cancelBarButtonItemTapped() {
        setEditing(false, animated: true)
        setupNavigationBarButtons()
        viewModel.dispatch(.navigationBarAction(.didTapCancel))
    }
    
    @objc private func selectAllBarButtonItemTapped() {
        viewModel.dispatch(.navigationBarAction(.didTapSelectAll))

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
            sortType: viewModel.videoRevampSortOrderType.megaSortOrderType.toSortOrderEntity(),
            isVideosRevampExplorer: true,
            isFilterEnabled: true,
            isSelectHidden: viewModel.isSelectHidden,
            isEmptyState: false,
            isFilterActive: viewModel.isFilterActive
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
