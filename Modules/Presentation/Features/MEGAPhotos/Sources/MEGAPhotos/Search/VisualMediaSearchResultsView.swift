import MEGADesignToken
import MEGASwiftUI
import SwiftUI

public struct VisualMediaSearchResultsView: View {
    @StateObject private var viewModel: VisualMediaSearchResultsViewModel
    
    public init(
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
            .onDisappear {
                Task {
                    await viewModel.onViewDisappear()
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .recentlySearched(let items):
            VisualMediaSearchHistoryView(searchedItems: items)
        case .empty:
            EmptyView()
        default:
            LoadingSpinner()
        }
    }
}

#Preview {
    VisualMediaSearchResultsView(
        viewModel: VisualMediaSearchResultsViewModel(
            visualMediaSearchHistoryUseCase: Preview_VisualMediaSearchHistoryUseCase()))
}
