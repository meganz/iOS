import SwiftUI

// This is the wrapper for displaying search bar in SwiftUI views when they are wrapped in UIHostingController.
// It is currently used in the new cloud drive, you can check CloudDriveViewControllerFactory.
// Since .searchable needs to be wrapped in NavigationStack, using .searchable would result in
// two navigation bars, and then one would have to be hidden, which is not the best practice.
// When we at some point, move to SwiftUI navigation, we should consider removing this class and
// use .searchable.
class SearchBarUIHostingController<Content>: UIHostingController<Content> where Content: View {
    var wrapper: SearchControllerWrapper?
    var backButtonTitle: String?

    init(
        rootView: Content,
        wrapper: SearchControllerWrapper,
        backButtonTitle: String?
    ) {
        super.init(rootView: rootView)
        self.wrapper = wrapper
        self.backButtonTitle = backButtonTitle
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.searchController = wrapper?.searchController ?? UISearchController()
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.hidesBackButton = true
        definesPresentationContext = true

        if let backButtonTitle {
            setMenuCapableBackButtonWith(menuTitle: backButtonTitle)
        }

        wrapper?.onUpdateSearchBarVisibility = { [weak self] isVisible in
            guard let self, let wrapper = self.wrapper else { return }
            self.navigationItem.searchController = isVisible ? wrapper.searchController : nil
        }
    }
}

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
        self.searchController = UISearchController.customSearchController(searchResultsUpdaterDelegate: self, searchBarDelegate: self)
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
