import SwiftUI

struct SearchResultsThumbnailView: View {
    @ObservedObject var viewModel: SearchResultsViewModel

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                view(items: viewModel.folderListItems, proxy: proxy)
                view(items: viewModel.fileListItems, proxy: proxy)
            }
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
                    Task {
                        await viewModel.onItemAppear(item)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}
