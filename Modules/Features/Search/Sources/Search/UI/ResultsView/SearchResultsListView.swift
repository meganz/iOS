import SwiftUI
struct SearchResultsListView: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    @Environment(\.editMode) private var editMode

    public init(viewModel: @autoclosure @escaping () -> SearchResultsViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Group {
            if viewModel.isSelectionEnabled {
                selectableListContent
            } else {
                nonselectableListContent
            }
        }
        .listStyle(.plain)
        .tint(viewModel.colorAssets.checkmarkBackgroundTintColor)
    }

    private var selectableListContent: some View {
        List(selection: $viewModel.selectedRowIds) {
            listSectionContent
        }
        .onChange(of: editMode?.wrappedValue) { newMode in
            if newMode == .active {
                viewModel.handleEditingChanged(true)
            }
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

    private var nonselectableListContent: some View {
        List {
            listSectionContent
        }
    }

    private var listSectionContent: some View {
        Section(header: listHeaderView) {
            ForEach(viewModel.listItems) { item in
                rowContent(rowViewModel: item)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        // `viewModel.onItemAppear(item)` is meant to trigger `loadMore` logic.
                        // We need to use `.onAppear` instead of `.task` so `loadMore` cannot be cancelled and cause a bug.
                        Task {
                            await viewModel.onItemAppear(item)
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func rowContent(rowViewModel: SearchResultRowViewModel) -> some View {
        if viewModel.usesRevampedLayout {
            RevampedSearchResultRowView(viewModel: rowViewModel)
        } else {
            SearchResultRowView(viewModel: rowViewModel)
                .listRowSeparatorTint(viewModel.colorAssets.listRowSeparator)
                .listRowBackground(Color.clear)
        }
    }
}
