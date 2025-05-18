import MEGAAppPresentation
import MEGADomain
import Search
import SwiftUI

// This is the wrapper for displaying search bar in SwiftUI views when they are wrapped in UIHostingController.
// It is currently used in the new cloud drive, you can check CloudDriveViewControllerFactory.
// Since .searchable needs to be wrapped in NavigationStack, using .searchable would result in
// two navigation bars, and then one would have to be hidden, which is not the best practice.
// When we at some point, move to SwiftUI navigation, we should consider removing this class and
// use .searchable.

// Add delegate methods for BrowserViewControllerDelegate, should end editing
class SearchBarUIHostingController<Content>: UIHostingController<Content>, AudioPlayerPresenterProtocol where Content: View {
    private var wrapper: SearchControllerWrapper?
    private var selectionHandler: SearchControllerSelectionHandler?
    private var toolbar: UIToolbar?
    private var backButtonTitle: String?
    private var toolbarBuilder: CloudDriveBottomToolbarItemsFactory
    private var browseDelegate: BrowserViewControllerDelegateHandler
    private var searchBarVisible: Bool
    let matchingNodeProvider: CloudDriveMatchingNodeProvider
    private weak var audioPlayerManager: (any AudioPlayerHandlerProtocol)?
    private var selectionModeEnabled = false
    
    // 状态管理
    private let stateQueue = DispatchQueue(label: "com.mega.searchbar.state", qos: .userInitiated)
    private let stateLock = NSLock()
    private var pendingUpdates: [() -> Void] = []
    private var cleanupTasks: [() -> Void] = []
    
    private enum ViewState {
        case initializing
        case ready
        case disappearing
        case disposed
    }
    
    private var viewState: ViewState = .initializing
    
    init(
        rootView: Content,
        wrapper: SearchControllerWrapper,
        selectionHandler: SearchControllerSelectionHandler,
        toolbarBuilder: CloudDriveBottomToolbarItemsFactory,
        backButtonTitle: String?,
        searchBarVisible: Bool,
        matchingNodeProvider: CloudDriveMatchingNodeProvider,
        audioPlayerManager: some AudioPlayerHandlerProtocol
    ) {
        self.wrapper = wrapper
        self.selectionHandler = selectionHandler
        self.toolbarBuilder = toolbarBuilder
        self.backButtonTitle = backButtonTitle
        self.browseDelegate = BrowserViewControllerDelegateHandler()
        self.searchBarVisible = searchBarVisible
        self.matchingNodeProvider = matchingNodeProvider
        self.audioPlayerManager = audioPlayerManager
        super.init(rootView: rootView)
        
        setupInitialState()
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewState = .ready
        processPendingUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewState = .disappearing
        removeToolbar(animated: false)
        cleanSearchController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.hidesBackButton = true
        
        let toolbar = UIToolbar(frame: .zero)
        self.toolbar = toolbar
        if let backButtonTitle {
            setMenuCapableBackButtonWith(menuTitle: backButtonTitle)
        }
        self.navigationItem.searchController = searchBarVisible ? wrapper?.searchController : nil
        wrapper?.onUpdateSearchBarVisibility = { [weak self] isVisible in
            guard let self, let wrapper = self.wrapper else { return }
            self.searchBarVisible = isVisible
            if isVisible {
                wrapper.attachToViewController(self)
            } else {
                navigationItem.searchController = nil
            }
        }
        
        selectionHandler?.onSelectionModeChange = { [weak self] enabled, config in
            guard let self else { return }
            
            selectionModeEnabled = enabled
            
            if enabled {
                addToolbar(for: config, animated: true)
            } else {
                removeToolbar(animated: true)
            }
            if let audioPlayerManager, audioPlayerManager.isPlayerAlive() {
                audioPlayerManager.playerHidden(enabled, presenter: self)
            }
        }
        
        selectionHandler?.onSelectionChanged = { [weak self] config in
            self?.updateToolbar(with: config)
        }
        
        browseDelegate.endEditingMode = { [weak self] in
            self?.removeToolbar(animated: true)
        }
        
        if let searchBar = self.wrapper?.searchController.searchBar {
            AppearanceManager.forceSearchBarUpdate(searchBar,
                                                   backgroundColorWhenDesignTokenEnable: UIColor.surface1Background())
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeToolbar(animated: animated)
    }
    
    private func setupInitialState() {
        addCleanupTask { [weak self] in
            self?.wrapper?.onUpdateSearchBarVisibility = nil
            self?.selectionHandler?.onSelectionModeChange = nil
            self?.selectionHandler?.onSelectionChanged = nil
            self?.browseDelegate.endEditingMode = nil
        }
    }
    
    private func updateState(_ update: @escaping () -> Void) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        if viewState == .ready {
            DispatchQueue.main.async {
                update()
            }
        } else {
            pendingUpdates.append(update)
        }
    }
    
    private func processPendingUpdates() {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            let updates = self.pendingUpdates
            self.pendingUpdates.removeAll()
            
            DispatchQueue.main.async {
                updates.forEach { $0() }
            }
        }
    }
    
    deinit {
        CrashlyticsLogger.log(category: .viewLifecycle, "SearchBarUIHostingController deinit - Before removeToolbar")

        cleanup()
        
        CrashlyticsLogger.log(category: .viewLifecycle, "SearchBarUIHostingController deinit.")
    }
    
    // MARK: - CancelSearch outside the controller
    func cancelActiveSearch() {
        wrapper?.cancelSearch()
    }
    
    // MARK: - UI Updates
    private func updateSearchBarVisibility(_ isVisible: Bool) {
        updateState { [weak self] in
            guard let self = self else { return }
            self.searchBarVisible = isVisible
            if isVisible {
                self.wrapper?.attachToViewController(self)
            } else {
                self.navigationItem.searchController = nil
            }
        }
    }
    
    private func updateSelectionMode(_ enabled: Bool, config: BottomToolbarConfig) {
        updateState { [weak self] in
            guard let self = self else { return }
            self.selectionModeEnabled = enabled
            
            if enabled {
                self.addToolbar(for: config, animated: true)
            } else {
                self.removeToolbar(animated: true)
            }
            
            if let audioPlayerManager = self.audioPlayerManager,
               audioPlayerManager.isPlayerAlive() {
                audioPlayerManager.playerHidden(enabled, presenter: self)
            }
        }
    }
    
    private func updateToolbar(with config: BottomToolbarConfig) {
        updateState { [weak self] in
            self?.configureToolbar(with: config)
        }
    }
    
    // MARK: - Toolbar Management
    private func configureToolbar(with config: BottomToolbarConfig) {
        guard let toolbar = toolbar else { return }
        let items = toolbarBuilder.buildToolbarItems(
            config: config,
            parent: self,
            browseDelegate: browseDelegate
        )
        
        let flexibleItem = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbar.items = items.flatMap { if $0 == items.last { [$0] } else { [$0, flexibleItem] } }
    }
    
    private func removeToolbar(animated: Bool) {
        updateState { [weak self] in
            guard let self = self, let toolbar = self.toolbar else { return }
            
            if animated {
                UIView.animate(
                    withDuration: 0.33,
                    animations: {
                        toolbar.alpha = 0
                    },
                    completion: { _ in
                        toolbar.removeFromSuperview()
                    }
                )
            } else {
                toolbar.removeFromSuperview()
            }
        }
    }
    
    private func addToolbar(for config: BottomToolbarConfig, animated: Bool = false) {
        updateState { [weak self] in
            guard let self = self, let toolbar = self.toolbar else { return }
            
            toolbar.alpha = 0
            self.configureToolbar(with: config)
            
            self.tabBarController?.view.addSubview(toolbar)
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            
            if let tabBar = self.tabBarController?.tabBar {
                NSLayoutConstraint.activate([
                    toolbar.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 0),
                    toolbar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: 0),
                    toolbar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor, constant: 0),
                    toolbar.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor, constant: 0)
                ])
            }
            
            UIView.animate(
                withDuration: animated ? 0.33 : 0,
                animations: {
                    toolbar.alpha = 1
                }
            )
        }
    }
    
    // MARK: - Cleanup
    private func addCleanupTask(_ task: @escaping () -> Void) {
        cleanupTasks.append(task)
    }
    
    private func cleanup() {
        cleanupTasks.forEach { $0() }
        cleanupTasks.removeAll()
    }
    
    // MARK: - Public Methods
    func cleanSearchController() {
        wrapper?.cancelSearch()
        navigationItem.searchController = nil
    }
    
    // MARK: - AudioPlayerPresenterProtocol
    public func updateContentView(_ height: CGFloat) {
        updateState { [weak self] in
            self?.additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
        }
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
    
    /**
     ```text
     0  libdispatch.dylib              0x5508 _dispatch_assert_queue_fail + 120
     1  libdispatch.dylib              0x371a8 dispatch_assert_queue$V2.cold.2 + 114
     2  libdispatch.dylib              0x548c dispatch_assert_queue + 108
     3  UIKitCore                      0x110c38 -[UIImageView _mainQ_beginLoadingIfApplicable] + 76
     4  UIKitCore                      0x110b28 -[UIImageView setHidden:] + 68
     ```
     ### 崩苦分析
     分析可能的原因：
     - 溃发生在 `com.apple.SwiftUI.AsyncRenderer` 线程中，崩溃的根本原因就是没有在主线程更新了`UIImageView`这个UI组件，在Pro、Max、Plus机型上会偶现，推测是他们屏幕大或者分辨率高，在ToolBar或NavigationBar上面可以有更多的按钮，导致异步渲染的负载更大，状态更新时更容易出现竞态条件，特别是如果快速切换视图状态下
     - `SwiftUI`和`UIKit`的生命周期不同步，在`UIKit`的视图释放的时候可能SwiftUI因为状态更新还在更新视图，导致异常
     
     ### 解决方案
     - 确保所有的UI操作都在主线程执行
     - 尽量不要在deinit做引用self的操作，销毁过程中，涉及到UIKit和SwiftUI的释放，可能会出现访问野指针的情况
     - 同步UIKit和SwiftUI的生命周期状态，尽量做到同步
     
     */
}

// responsible for communicating selected state and selected items
class SearchControllerSelectionHandler {
    var onSelectionModeChange: ((_ enabled: Bool, _ config: BottomToolbarConfig) -> Void)?
    var onSelectionChanged: ((BottomToolbarConfig) -> Void)?
}

// responsible for communicating search status and search queries
class SearchControllerWrapper: NSObject {
    var searchController: UISearchController = UISearchController()
    var onSearch: ((String) -> Void)?
    var onCancel: (() -> Void)?
    var onUpdateSearchBarVisibility: ((Bool) -> Void)?
    private var searchText: String?
    
    init(
        onSearch: ((String) -> Void)?,
        onCancel: (() -> Void)?
    ) {
        super.init()
        self.searchController = UISearchController.customSearchController(
            searchResultsUpdaterDelegate: self,
            searchBarDelegate: self
        )
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.onSearch = onSearch
        self.onCancel = onCancel
    }
    
    func cancelSearch() {
        onCancel?()
        searchController.searchBar.text = ""
        searchController.isActive = false
    }
    
    /// This function is use when we want to assign the wrapper to a ViewController.
    /// Discussion: The function is needed because in case we assign and unassign a searchController to a VC, the OS will automatically clear the search text.
    /// Therefore we need to use this function when we  re-attach the searchController to a VC so that the search text can still be instact.
    /// - Parameter vc: The ViewController we want to attach the searchController to.
    func attachToViewController(_ vc: UIViewController) {
        vc.navigationItem.searchController = searchController
        searchController.searchBar.text = searchText
    }
}

// MARK: - UISearchResultsUpdating
extension SearchControllerWrapper: UISearchResultsUpdating {
    
    var isSearching: Bool {
        searchController.isActive && !isSearchBarEmpty
    }
    
    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text,
              searchController.isActive
        else { return }
        
        searchText = searchString
        onSearch?(searchString)
    }
}

// MARK: - UISearchBarDelegate
extension SearchControllerWrapper: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        onCancel?()
    }
}
/// For handling changes to parent nodes structure, we need to know the current input node is matching the current node that is displayed on the screen.
/// CloudDriveMatchingNodeProvider is used for that purpose
struct CloudDriveMatchingNodeProvider {
    let matchingNode: (NodeEntity) -> Bool
}
