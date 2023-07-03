import UIKit

public extension UISearchController {
    @objc static func customSearchController(searchResultsUpdaterDelegate: any UISearchResultsUpdating,
                                             searchBarDelegate: any UISearchBarDelegate) -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = searchResultsUpdaterDelegate
        searchController.searchBar.delegate = searchBarDelegate
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.isTranslucent = false
        
        return searchController
    }
}
