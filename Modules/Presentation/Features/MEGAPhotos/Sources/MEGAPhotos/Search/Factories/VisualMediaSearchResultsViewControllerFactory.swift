import UIKit

public struct VisualMediaSearchResultsViewControllerFactory {
    
    @MainActor
    public static func makeViewController(
        viewModel: VisualMediaSearchResultsViewModel
    ) -> UIViewController & UISearchResultsUpdating {
        VisualMediaSearchResultsViewController(
            viewModel: viewModel)
    }
}
