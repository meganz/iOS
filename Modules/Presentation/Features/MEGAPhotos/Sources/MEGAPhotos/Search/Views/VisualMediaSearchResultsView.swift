import MEGADesignToken
import MEGASwiftUI
import SwiftUI

public struct VisualMediaSearchResultsView: View {
    @StateObject private var viewModel: VisualMediaSearchResultsViewModel
    
    init(
        viewModel: @autoclosure @escaping () -> VisualMediaSearchResultsViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        content
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
            .background(TokenColors.Background.page.swiftUI)
            .task {
                await viewModel.monitorSearchResults()
            }
            .task {
                await viewModel.handleSelectedItemNavigation()
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            VisualMediaSearchLoadingView()
        case .recentlySearched(let items):
            VisualMediaSearchHistoryView(
                searchedItems: items,
                selectedRecentlySearched: $viewModel.selectedRecentlySearched)
        case .searchResults(let results):
            VisualMediaSearchResultFoundView(
                results: results,
                selectedItem: $viewModel.selectedVisualMediaResult)
        case .empty:
            EmptySearchView()
        }
    }
}
