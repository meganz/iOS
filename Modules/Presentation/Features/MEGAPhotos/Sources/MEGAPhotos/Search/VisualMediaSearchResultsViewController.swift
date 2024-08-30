import SwiftUI

public class VisualMediaSearchResultsViewController: UIHostingController<VisualMediaSearchResultsView> {
    private let viewModel: VisualMediaSearchResultsViewModel
    
    public init(viewModel: VisualMediaSearchResultsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: VisualMediaSearchResultsView(viewModel: viewModel))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UISearchResultsUpdating

extension VisualMediaSearchResultsViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.searchText = searchText
    }
}
