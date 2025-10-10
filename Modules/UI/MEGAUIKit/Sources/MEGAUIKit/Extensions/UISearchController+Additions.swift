import UIKit

public extension UISearchController {
    @objc static func customSearchController(
        searchResultsUpdaterDelegate: any UISearchResultsUpdating,
        searchBarDelegate: any UISearchBarDelegate,
        searchControllerDelegate: (any UISearchControllerDelegate)?
    ) -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = searchResultsUpdaterDelegate
        searchController.searchBar.delegate = searchBarDelegate
        searchController.delegate = searchControllerDelegate
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.isTranslucent = false
        
        return searchController
    }
}
