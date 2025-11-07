import MEGADesignToken
import SwiftUI

struct SearchResultsThumbnailView: View {
    @ObservedObject var viewModel: SearchResultsViewModel

    var body: some View {
        GeometryReader { proxy in
            if viewModel.usesRevampedLayout {
                revampedScrollViewContent(proxy: proxy)
            } else {
                scrollViewContent(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func scrollViewContent(proxy: GeometryProxy) -> some View {
        ScrollView {
            view(items: viewModel.folderListItems, proxy: proxy)
            view(items: viewModel.fileListItems, proxy: proxy)
        }
    }

    private func view(items: [SearchResultRowViewModel], proxy: GeometryProxy) -> some View {
        LazyVGrid(
            columns: viewModel.columns(proxy.size.width)
        ) {
            ForEach(items) { item in
                SearchResultThumbnailItemView(
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
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func revampedScrollViewContent(proxy: GeometryProxy) -> some View {
        ScrollView {
            revampedGridView(items: viewModel.listItems, proxy: proxy)
        }
    }

    private func revampedGridView(items: [SearchResultRowViewModel], proxy: GeometryProxy) -> some View {
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
