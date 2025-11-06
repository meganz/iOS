import UIKit

public struct VisualMediaSearchResultsViewControllerFactory {
    
    @MainActor
    public static func makeViewController(
        viewModel: VisualMediaSearchResultsViewModel
    ) -> UIViewController {
        VisualMediaSearchResultsViewController(
            viewModel: viewModel)
    }
}
