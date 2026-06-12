import MEGADesignToken
import SwiftUI
struct SearchResultsListView<Header: View>: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    @ObservedObject var rowHighlighter: SearchResultsRowHighlighter
    @Environment(\.editMode) private var editMode
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

    public var body: some View {
        ScrollViewReader { proxy in
            Group {
                if viewModel.isSelectionEnabled {
                    selectableListContent
                } else {
                    nonselectableListContent
                }
            }
            .onChange(of: rowHighlighter.scrollToResultId) { resultId in
                scrollToHighlightedRow(resultId: resultId, proxy: proxy)
            }
            // When the list goes from empty to non-empty
            // if a auto-scroll is pending, fire it.
            .onChange(of: viewModel.listItems.isEmpty) { isEmpty in
                guard !isEmpty, let pendingResultId = rowHighlighter.scrollToResultId else { return }
                scrollToHighlightedRow(resultId: pendingResultId, proxy: proxy)
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .tint(TokenColors.Components.selectionControlAlt.swiftUI)
    }

    private func scrollToHighlightedRow(resultId: ResultId?, proxy: ScrollViewProxy) {
        guard let resultId else { return }
        if viewModel.listItems.contains(where: { $0.result.id == resultId }) {
            scroll(to: resultId, proxy: proxy)
        } else {
            // The target may live on a page that hasn't been mapped yet (the list
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
    
    @ViewBuilder
    private var selectableListContent: some View {
        let list = List(selection: $viewModel.selectedRowIds) {
            listSectionContent
        }
        .onChange(of: editMode?.wrappedValue) { newMode in
            if newMode == .active {
                viewModel.handleEditingChanged(true)
            }
        }

        if #available(iOS 17.0, *) {
            list
                .contentMargins(.top, 0, for: .scrollContent)
        } else {
            list
        }
    }

    @ViewBuilder
    private var listHeaderView: some View {
        if let listHeaderViewModel = viewModel.listHeaderViewModel {
            HStack {
                Text(listHeaderViewModel.leadingText)
                Image(uiImage: listHeaderViewModel.icon)
                Text(listHeaderViewModel.trailingText)
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(viewModel.colorAssets.listHeaderTextColor)
        }
    }

    @ViewBuilder
    private var nonselectableListContent: some View {
        let list = List {
            listSectionContent
        }

        if #available(iOS 17.0, *) {
            list
                .contentMargins(.top, 0, for: .scrollContent)
        } else {
            list
        }
    }

    @ViewBuilder
    private var listSectionContent: some View {
        header()
            .listRowInsets(.init())
            .listRowSeparator(.hidden)

        Section {
            ForEach(viewModel.listItems) { item in
                rowContent(rowViewModel: item)
                    .onAppear {
                        // `viewModel.onItemAppear(item)` is meant to trigger `loadMore` logic.
                        // We need to use `.onAppear` instead of `.task` so `loadMore` cannot be cancelled and cause a bug.
                        Task {
                            await viewModel.onItemAppear(item)
                        }
                    }
            }
        } header: {
            listHeaderView
        }
    }

    @ViewBuilder
    private func rowContent(rowViewModel: SearchResultRowViewModel) -> some View {
        if let custom = viewModel.rowBuilder?(rowViewModel.result) {
            custom
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else {
            RevampedSearchResultRowView(
                viewModel: rowViewModel,
                selected: $viewModel.selectedResultIds,
                isHighlightTarget: rowHighlighter.highlightedResultId == rowViewModel.result.id,
                hasFlashedForCurrentTarget: $rowHighlighter.hasFlashedForCurrentTarget
            )
            .listRowSeparator(.hidden)
        }
    }
}
