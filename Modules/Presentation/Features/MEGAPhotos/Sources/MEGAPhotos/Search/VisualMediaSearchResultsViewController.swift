import SwiftUI

class VisualMediaSearchResultsViewController: UIHostingController<VisualMediaSearchResultsView> {
    private let viewModel: VisualMediaSearchResultsViewModel
    
    init(viewModel: VisualMediaSearchResultsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: VisualMediaSearchResultsView(viewModel: viewModel))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UISearchResultsUpdating

extension VisualMediaSearchResultsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.searchText = searchText
    }
}

// MARK: - UISearchBarDelegate

extension VisualMediaSearchResultsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Task {
            await viewModel.saveSearch()
        }
    }
}
