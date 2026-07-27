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
                    gridView(items: viewModel.listItems, geometryProxy: geometryProxy, scrollProxy: scrollProxy)
                }
                .onChange(of: rowHighlighter.scrollToResultId) { _, resultId in
                    scrollToHighlightedRow(resultId: resultId, proxy: scrollProxy)
                }
                .onChange(of: viewModel.listItems.isEmpty) { _, isEmpty in
                    guard !isEmpty, let pendingResultId = rowHighlighter.scrollToResultId else { return }
                    scrollToHighlightedRow(resultId: pendingResultId, proxy: scrollProxy)
                }
            }
        }
    }

    private func gridView(items: [SearchResultRowViewModel], geometryProxy: GeometryProxy, scrollProxy: ScrollViewProxy) -> some View {
        LazyVGrid(
            columns: viewModel.columns(geometryProxy.size.width)
        ) {
            ForEach(items) { item in
                RevampedSearchResultThumbnailView(
                    viewModel: item,
                    selected: $viewModel.selectedResultIds,
                    selectionEnabled: $viewModel.editing,
                    isFlashing: rowHighlighter.flashingResultId == item.result.id,
                    isPendingFlash: rowHighlighter.pendingFlashResultId == item.result.id,
                    onReadyToFlash: { rowHighlighter.beginFlashIfPending(for: item.result.id) }
                )
                .onAppear {
                    // `viewModel.onItemAppear(item)` is meant to trigger `loadMore` logic.
                    // We need to use `.onAppear` instead of `.task` so `loadMore` cannot be cancelled and cause a bug.
                    Task {
                        await viewModel.onItemAppear(item)
                    }
                    // The pending scroll target is now laid out with its real
                    // size — re-center on it accurately, then consume.
                    if item.result.id == rowHighlighter.scrollToResultId {
                        scroll(to: item.result.id, proxy: scrollProxy, consume: true)
                    }
                }
            }
        }
        .padding(.horizontal, TokenSpacing._3)
    }

    private func scrollToHighlightedRow(resultId: ResultId?, proxy: ScrollViewProxy) {
        guard let resultId else { return }
        if viewModel.listItems.contains(where: { $0.result.id == resultId }) {
            scroll(to: resultId, proxy: proxy, consume: true)
        } else {
            // The target may live on a page that hasn't been mapped yet (the grid
            // is paginated). Load up to it first, then scroll. Leave the request
            // pending so the target cell re-centers accurately (and consumes it)
            // once it has appeared with its real, laid-out size.
            Task {
                await viewModel.loadResults(untilResultIdLoaded: resultId)
                scroll(to: resultId, proxy: proxy, consume: false)
            }
        }
    }

    private func scroll(to resultId: ResultId, proxy: ScrollViewProxy, consume: Bool) {
        guard let row = viewModel.listItems.first(where: { $0.result.id == resultId }) else { return }
        withAnimation {
            proxy.scrollTo(row.id, anchor: .center)
        }
        // Consume the one-shot request so the same row isn't re-scrolled on
        // unrelated state changes.
        if consume {
            rowHighlighter.scrollToResultId = nil
        }
    }
}
