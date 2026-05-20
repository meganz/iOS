import MEGADesignToken
import SwiftUI

struct SearchResultsThumbnailView<Header: View>: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    @ViewBuilder private let header: () -> Header

    public init(
        viewModel: @autoclosure @escaping () -> SearchResultsViewModel,
        @ViewBuilder header: @escaping () -> Header
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel())
        self.header = header
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                header()
                gridView(items: viewModel.listItems, proxy: proxy)
            }
        }
    }

    private func gridView(items: [SearchResultRowViewModel], proxy: GeometryProxy) -> some View {
        LazyVGrid(
            columns: viewModel.columns(proxy.size.width)
        ) {
            ForEach(items) { item in
                RevampedSearchResultThumbnailView(
                    viewModel: item,
                    selected: $viewModel.selectedResultIds,
                    selectionEnabled: $viewModel.editing
                )
                .onAppear {
                    // `viewModel.onItemAppear(item)` is meant to trigger `loadMore` logic.
                    // We need to use `.onAppear` instead of `.task` so `loadMore` cannot be cancelled and cause a bug.
                    Task {
                        await viewModel.onItemAppear(item)
                    }
                }
            }
        }
        .padding(.horizontal, TokenSpacing._3)
    }
}
