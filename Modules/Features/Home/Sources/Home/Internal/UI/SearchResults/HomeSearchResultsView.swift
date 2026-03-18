import Combine
import MEGAAppPresentation
import MEGAUIKit
import Search
import SwiftUI

struct HomeSearchResultsView: View {

    struct Dependency {
        let searchConfig: SearchConfig
        let resultsProvider: any SearchResultsProviding
        let searchResultsSelectionHandler: any NodeSelectionHandling
        let searchResultNodeActionHandler: any NodesActionHandling
    }

    @StateObject private var viewModel: HomeSearchResultsViewModel

    @Binding private var searchText: String
    private let dependency: Dependency

    init(dependency: Dependency, searchText: Binding<String>) {
        self.dependency = dependency
        _searchText = searchText
        _viewModel = StateObject(wrappedValue: HomeSearchResultsViewModel(
            dependency: .init(
                searchConfig: dependency.searchConfig,
                resultsProvider: dependency.resultsProvider,
                pageLayout: .list
            )
        ))
    }

    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .background()
            .onChange(of: searchText) {
                viewModel.searchText = $0
            }
            .onReceive(viewModel.$selection.compactMap { $0 }) {
                dependency.searchResultsSelectionHandler.handle(selection: $0)
            }
            .onReceive(viewModel.$nodeAction.compactMap { $0 }) {
                dependency.searchResultNodeActionHandler.handle(action: $0)
            }
    }
}
