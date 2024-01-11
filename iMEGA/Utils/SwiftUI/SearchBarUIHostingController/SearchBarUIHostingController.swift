import SwiftUI

// This is the wrapper for displaying search bar in SwiftUI views when they are wrapped in UIHostingController.
// It is currently used in the new cloud drive, you can check CloudDriveViewControllerFactory.
// Since .searchable needs to be wrapped in NavigationStack, using .searchable would result in
// two navigation bars, and then one would have to be hidden, which is not the best practice.
// When we at some point, move to SwiftUI navigation, we should consider removing this class and
// use .searchable.
class SearchBarUIHostingController<Content>: UIHostingController<Content> where Content: View {
    var wrapper: SearchControllerWrapper?

    init(rootView: Content, wrapper: SearchControllerWrapper) {
        super.init(rootView: rootView)
        self.wrapper = wrapper
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

    // We need current search text in order to not trigger not needed searching with empty string ""
    // when the search controller becomes active
    private var searchText: String?

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

        // We need to trigger search only if the input user types is not empty or if the user has
        // previously entered some text in the search bar.
        // By doing this, we avoid not needed searching with empty string ""
        // when the search controller becomes active
        guard (searchText != nil && searchText!.isNotEmpty) || searchString.isNotEmpty else { return }

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
