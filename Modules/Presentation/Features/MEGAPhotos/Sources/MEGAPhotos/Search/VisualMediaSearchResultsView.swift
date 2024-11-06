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
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .recentlySearched(let items):
            VisualMediaSearchHistoryView(
                searchedItems: items,
                selectedRecentlySearched: $viewModel.selectedRecentlySearched)
        case .searchResults(let albumCellViewModels, let photos):
            VisualMediaSearchResultFoundView(
                albumCellViewModels: albumCellViewModels,
                photos: photos,
                searchText: $viewModel.searchText)
        case .empty:
            EmptySearchView()
        default:
            LoadingSpinner()
        }
    }
}

#Preview {
    VisualMediaSearchResultsView(
        viewModel: VisualMediaSearchResultsViewModel(
            searchBarTextFieldUpdater: SearchBarTextFieldUpdater(),
            visualMediaSearchHistoryUseCase: Preview_VisualMediaSearchHistoryUseCase()))
}
