import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct TransferTabListView: View {
    @StateObject private var viewModel: TransferTabListViewModel
    /// Bound into `List(selection:)` and read for the selected-row highlight.
    @ObservedObject private var selection: TransferSelection
    private let emptyStateTitle: String
    private let onTransferCancelled: (TransferEntity) -> Void
    private let onTransferRetried: @MainActor () -> Void

    init(
        tab: TransfersTab,
        dependency: TransferTabDependency,
        selection: TransferSelection,
        onTransferCancelled: @escaping (TransferEntity) -> Void,
        onTransferRetried: @MainActor @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: TransferTabListViewModel(tab: tab, dependency: dependency, selection: selection)
        )
        _selection = ObservedObject(wrappedValue: selection)
        emptyStateTitle = tab.emptyStateTitle
        self.onTransferCancelled = onTransferCancelled
        self.onTransferRetried = onTransferRetried
    }

    var body: some View {
        content
            .task { await viewModel.monitorTransferEvents() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.rows.isEmpty {
            if viewModel.isLoaded {
                RevampedContentUnavailableView(
                    viewModel: .transfersEmptyState(title: emptyStateTitle)
                )
                .pageBackground()
            } else {
                Color.clear
            }
        } else {
            listContent
        }
    }

    @ViewBuilder
    private var listContent: some View {
        // Selection-bound unconditionally: outside select mode the binding is
        // inert (the native checkboxes only appear in edit mode), while swapping
        // in a second `List` on mode changes would reset the scroll position.
        List(selection: $selection.selectedTags) {
            ForEach(viewModel.rows) { row in
                TransferResultRowView(viewModel: row, onCancelled: onTransferCancelled, onRetried: onTransferRetried)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    // Selected rows carry the design's surface-1 highlight in
                    // place of the native selected-cell grey.
                    .listRowBackground(
                        selection.selectedTags.contains(row.id)
                            ? TokenColors.Background.surface1.swiftUI
                            : Color.clear
                    )
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .contentMargins(.top, 0, for: .scrollContent)
        // Fills the native edit-mode checkbox: Accent.900 in light, Accent.500 in
        // dark — the same circle Cloud Drive shows.
        .tint(TokenColors.Components.selectionControlAlt.swiftUI)
    }
}
