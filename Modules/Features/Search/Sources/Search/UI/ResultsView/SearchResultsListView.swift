import MEGADesignToken
import SwiftUI
struct SearchResultsListView<Header: View>: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    @Environment(\.editMode) private var editMode
    @ViewBuilder private let header: () -> Header

    public init(
        viewModel: @autoclosure @escaping () -> SearchResultsViewModel,
        @ViewBuilder header: @escaping () -> Header
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel())
        self.header = header
    }

    public var body: some View {
        Group {
            if viewModel.isSelectionEnabled {
                selectableListContent
            } else {
                nonselectableListContent
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .tint(
            viewModel.usesRevampedLayout ? TokenColors.Components.selectionControlAlt.swiftUI : viewModel.colorAssets.checkmarkBackgroundTintColor
        )
    }

    @ViewBuilder
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

    @ViewBuilder
    private var nonselectableListContent: some View {
        List {
            listSectionContent
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
        if viewModel.usesRevampedLayout {
            RevampedSearchResultRowView(viewModel: rowViewModel, selected: $viewModel.selectedResultIds)
                .listRowSeparator(.hidden)
        } else {
            SearchResultRowView(viewModel: rowViewModel)
                .listRowSeparatorTint(viewModel.colorAssets.listRowSeparator)
                .listRowBackground(Color.clear)
        }
    }
}
