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
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.hidesBackButton = true
        navigationItem.searchController = wrapper?.searchController
        let toolbar = UIToolbar(frame: .zero)
        self.toolbar = toolbar
        if let backButtonTitle {
            setMenuCapableBackButtonWith(menuTitle: backButtonTitle)
        }
        self.navigationItem.searchController = searchBarVisible ? wrapper?.searchController : nil
        
        wrapper?.onUpdateSearchBarVisibility = { [weak self] isVisible in
            guard let self, let wrapper = self.wrapper else { return }
            self.searchBarVisible = isVisible
            self.navigationItem.searchController = isVisible ? wrapper.searchController : nil
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
                audioPlayerManager.playerHiddenIgnoringPlayerLifeCycle(enabled, presenter: self)
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
                                                   backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                                   traitCollection: self.traitCollection)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let audioPlayerManager, audioPlayerManager.isPlayerAlive() {
            audioPlayerManager.addDelegate(self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayerManager?.removeDelegate(self)
    }

    deinit {
        removeToolbar(animated: false)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            
            if let navigationBar = self.wrapper?.searchController.navigationController?.navigationBar {
                AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: self.traitCollection)
            }
            
            if let toolbar {
                AppearanceManager.forceToolbarUpdate(toolbar, traitCollection: self.traitCollection)
            }
            if let searchBar = self.wrapper?.searchController.searchBar {
                AppearanceManager.forceSearchBarUpdate(searchBar, 
                                                       backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                                       traitCollection: self.traitCollection)
            }
        }
    }
    
    // MARK: - AudioPlayerPresenterProtocol
    func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    // MARK: - Private methods
    
    private func updateToolbar(with config: BottomToolbarConfig) {
        configureToolbar(with: config)
    }
    
    private func configureToolbar(with config: BottomToolbarConfig) {
        guard let toolbar else { return }
        let items = toolbarBuilder.buildToolbarItems(
            config: config,
            parent: self,
            browseDelegate: browseDelegate
        )
        
        let flexibleItem = UIBarButtonItem(systemItem: .flexibleSpace)
        
        // insert flexibleItem to make all items evenly distributed
        toolbar.items = items.flatMap { if $0 == items.last { [$0] } else { [$0, flexibleItem] } }
    }
    
    private func removeToolbar(animated: Bool) {
        guard animated else {
            self.toolbar?.removeFromSuperview()
            return
        }

        UIView.animate(
            withDuration: 0.33,
            animations: {
                self.toolbar?.alpha = 0
            },
            completion: { _ in
                self.toolbar?.removeFromSuperview()
            }
        )
    }

    private func addToolbar(for config: BottomToolbarConfig, animated: Bool = false) {
        guard let toolbar else { return }

        toolbar.alpha = 0
        configureToolbar(with: config)

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
            withDuration: animated ? 0.33 : 0,
            animations: {
                toolbar.alpha = 1
            }
        )
    }
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
