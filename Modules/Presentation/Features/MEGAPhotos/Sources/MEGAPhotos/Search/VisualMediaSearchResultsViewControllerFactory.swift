import MEGADomain
import UIKit

public struct VisualMediaSearchResultsViewControllerFactory {
    
    @MainActor
    public static func makeViewController(searchBarTextFieldUpdater: SearchBarTextFieldUpdater) -> UIViewController & UISearchResultsUpdating {
        VisualMediaSearchResultsViewController(
            viewModel: VisualMediaSearchResultsViewModel(
                searchBarTextFieldUpdater: searchBarTextFieldUpdater,
                visualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCase()))
    }
}
