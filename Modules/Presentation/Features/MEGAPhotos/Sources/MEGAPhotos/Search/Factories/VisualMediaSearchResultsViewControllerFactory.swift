import MEGADomain
import UIKit

public struct VisualMediaSearchResultsViewControllerFactory {
    
    @MainActor
    public static func makeViewController(
        viewModel: VisualMediaSearchResultsViewModel
    ) -> UIViewController & UISearchResultsUpdating & UISearchBarDelegate {
        VisualMediaSearchResultsViewController(
            viewModel: viewModel)
    }
}
