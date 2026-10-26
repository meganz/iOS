import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct TransferTabListView: View {
    @StateObject private var viewModel: TransferTabListViewModel
    /// Bound into `List(selection:)` and read for the selected-row highlight.
    @ObservedObject private var selection: TransferSelection
    @Environment(\.editMode) private var editMode
    @State private var isSearchEditing = false
    private let isSearchable: Bool
    private let isReorderable: Bool
    private let emptyStateTitle: String
    private let onTransferCancelled: (TransferEntity) -> Void
    private let onTransferRetried: @MainActor () -> Void
    /// Carries the tag of the row whose tap-and-hold menu chose Select up to the
    /// screen, which enters select mode with it pre-selected.
    private let onRowSelectRequested: @MainActor (Int) -> Void

    init(
        tab: TransfersTab,
        dependency: TransferTabDependency,
        selection: TransferSelection,
        searchText: String,
        onSearchTextChanged: @MainActor @escaping (String) -> Void,
        onTransferCancelled: @escaping (TransferEntity) -> Void,
        onTransferRetried: @MainActor @escaping () -> Void,
        onRowSelectRequested: @MainActor @escaping (Int) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: TransferTabListViewModel(
                tab: tab,
                dependency: dependency,
                selection: selection,
                searchText: searchText,
                onSearchTextChanged: onSearchTextChanged
            )
        )
        _selection = ObservedObject(wrappedValue: selection)
        isSearchable = tab.isSearchable
        isReorderable = tab.isQueueOrdered
        emptyStateTitle = tab.emptyStateTitle
        self.onTransferCancelled = onTransferCancelled
        self.onTransferRetried = onTransferRetried
        self.onRowSelectRequested = onRowSelectRequested
    }

    var body: some View {
        content
            .task { await viewModel.monitorTransferEvents() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasTransfers {
            if viewModel.isLoaded {
                RevampedContentUnavailableView(
                    viewModel: .transfersEmptyState(title: emptyStateTitle)
                )
                .pageBackground()
            } else {
                Color.clear
            }
        } else {
            VStack(spacing: 0) {
                if showsSearchBar {
                    searchBar
                }
                // An overlay rather than a branch, so a search that briefly
                // matches nothing doesn't tear down the list.
                listContent
                    .overlay {
                        if viewModel.rows.isEmpty {
                            RevampedContentUnavailableView(viewModel: .noResults)
                                .pageBackground()
                        }
                    }
            }
        }
    }

    private var showsSearchBar: Bool {
        isSearchable && editMode?.wrappedValue.isEditing != true
    }

    private var searchBar: some View {
        SearchBarView(
            text: $viewModel.searchText,
            isEditing: $isSearchEditing,
            placeholder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel
        )
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
    }

    @ViewBuilder
    private var listContent: some View {
        // Selection-bound unconditionally: outside select mode the binding is
        // inert (the native checkboxes only appear in edit mode), while swapping
        // in a second `List` on mode changes would reset the scroll position.
        List(selection: $selection.selectedTags) {
            ForEach(viewModel.rows) { row in
                TransferResultRowView(
                    viewModel: row,
                    isReorderable: isReorderable,
                    onCancelled: onTransferCancelled,
                    onRetried: onTransferRetried,
                    onSelectRequested: { onRowSelectRequested(row.id) }
                )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    // Selected rows carry the design's surface-1 highlight in
                    // place of the native selected-cell grey.
                    //
                    // Unselected rows are painted the page colour rather than left clear: it reads
                    // the same in the list, but the tap-and-hold lift is UIKit's snapshot of the
                    // row, and a clear row snapshots to a transparent card that shows the dimmed
                    // backdrop straight through instead of lifting off it.
                    .listRowBackground(
                        selection.selectedTags.contains(row.id)
                            ? TokenColors.Background.surface1.swiftUI
                            : TokenColors.Background.page.swiftUI
                    )
            }
            // The list drives the drag and the lifted row; rows opt out with `moveDisabled`.
            .onMove(perform: isReorderable ? { moveRow(from: $0, to: $1) } : nil)
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
        .contentMargins(.top, 0, for: .scrollContent)
        // Fills the native edit-mode checkbox: Accent.900 in light, Accent.500 in
        // dark — the same circle Cloud Drive shows.
        .tint(TokenColors.Components.selectionControlAlt.swiftUI)
    }

    /// Reorders the list in the same pass as the drop, so the row doesn't spring back,
    /// then hands the move to the SDK.
    private func moveRow(from source: IndexSet, to destination: Int) {
        guard let reorder = viewModel.reorder(fromOffsets: source, toOffset: destination) else { return }
        Task { await viewModel.commitReorder(reorder) }
    }
}
