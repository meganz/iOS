import MEGADomain
import MEGARepo
import UIKit

public struct VisualMediaSearchResultsViewControllerFactory {
    
    @MainActor
    public static func makeViewController(searchBarTextFieldUpdater: SearchBarTextFieldUpdater) -> UIViewController & UISearchResultsUpdating & UISearchBarDelegate {
        VisualMediaSearchResultsViewController(
            viewModel: VisualMediaSearchResultsViewModel(
                searchBarTextFieldUpdater: searchBarTextFieldUpdater,
                visualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCase(
                    visualMediaSearchHistoryRepository: VisualMediaSearchHistoryCacheRepository.newRepo)))
    }
}
