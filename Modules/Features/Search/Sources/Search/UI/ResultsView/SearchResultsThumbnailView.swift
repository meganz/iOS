import MEGADesignToken
import SwiftUI

struct SearchResultsThumbnailView<Header: View>: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    @ObservedObject var rowHighlighter: SearchResultsRowHighlighter
    @ViewBuilder private let header: () -> Header

    public init(
        viewModel: @autoclosure @escaping () -> SearchResultsViewModel,
        rowHighlighter: SearchResultsRowHighlighter,
        @ViewBuilder header: @escaping () -> Header
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel())
        self.rowHighlighter = rowHighlighter
        self.header = header
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    header()
                    gridView(items: viewModel.listItems, proxy: geometryProxy)
                }
                .onChange(of: rowHighlighter.scrollToResultId) { resultId in
                    scrollToHighlightedRow(resultId: resultId, proxy: scrollProxy)
                }
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
                    selectionEnabled: $viewModel.editing,
                    isHighlightTarget: rowHighlighter.highlightedResultId == item.result.id,
                    highlightPersists: rowHighlighter.highlightPersists,
                    hasFlashedForCurrentTarget: $rowHighlighter.hasFlashedForCurrentTarget
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

    private func scrollToHighlightedRow(resultId: ResultId?, proxy: ScrollViewProxy) {
        guard let resultId else { return }
        if viewModel.listItems.contains(where: { $0.result.id == resultId }) {
            scroll(to: resultId, proxy: proxy)
        } else {
            // The target may live on a page that hasn't been mapped yet (the grid
            // is paginated). Load up to it first, then scroll.
            Task {
                await viewModel.loadResults(untilResultIdLoaded: resultId)
                scroll(to: resultId, proxy: proxy)
            }
        }
    }

    private func scroll(to resultId: ResultId, proxy: ScrollViewProxy) {
        guard let row = viewModel.listItems.first(where: { $0.result.id == resultId }) else { return }
        withAnimation {
            proxy.scrollTo(row.id, anchor: .center)
        }
        // Consume the one-shot request so the same row isn't re-scrolled on
        // unrelated state changes.
        rowHighlighter.scrollToResultId = nil
    }
}
