import Foundation
import MEGAUIComponent
import MEGAUIKit
import Search

/// View model for a single Transfers tab. Encapsulates the whole `Search` wiring
/// for that tab behind a single `SearchResultsContainerViewModel` — the public
/// entry point to Search — so the parent `TransfersListViewModel` never has to
/// hold or expose Search internals. Owned by each tab view (`ActiveTransfersTab`
/// / `CompletedTransfersTab` / `FailedTransfersTab`) as a `@StateObject`.
@MainActor
final class TransferTabViewModel: ObservableObject {
    let containerViewModel: SearchResultsContainerViewModel

    /// Called with this tab's live item count whenever it changes, while
    /// `observeItemCount()` is running. A plain output callback (not a SwiftUI
    /// `Binding`), so the count tracking is owned and unit-testable here while the
    /// view keeps the binding it writes into. Set once at construction.
    private let onItemCountChange: (Int) -> Void

    /// Builds the `SearchResultsContainerViewModel` (which owns the
    /// `SearchResultsViewModel`) around a transfer provider built from `dependency`
    /// and `filter`, reusing the shared registry-backed config. The list is a
    /// non-selectable, header-less view.
    /// - Parameters:
    ///   - dependency: shared, per-tab-reused Search dependencies.
    ///   - filter: which transfers this tab shows (active / completed / failed).
    ///   - emptyStateTitle: tab-specific empty-state message shown by the
    ///     container's content-unavailable view when the list has no rows.
    ///   - onItemCountChange: called with the tab's live item count whenever it
    ///     changes, while `observeItemCount()` is running.
    init(
        dependency: TransferTabDependency,
        filter: TransferSearchResultsProvider.Filter,
        emptyStateTitle: String,
        onItemCountChange: @escaping (Int) -> Void
    ) {
        self.onItemCountChange = onItemCountChange

        let provider = TransferSearchResultsProvider(
            filter: filter,
            inventoryUseCase: dependency.inventoryUseCase,
            counterUseCase: dependency.counterUseCase,
            registry: dependency.registry,
            locationResolver: dependency.locationResolver,
            filteringUserTransfers: dependency.filteringUserTransfers,
            clearTransfersUseCase: dependency.clearTransfersUseCase
        )

        let bridge = SearchBridge(
            selection: { _ in },
            context: { _, _ in },
            chipTapped: { _, _ in },
            sortingOrder: { .init(key: .name) },
            updateSortOrder: { _ in },
            chipPickerShowedHandler: { _ in }
        )

        let config = SearchConfig.transfers(registry: dependency.registry)

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: provider,
            bridge: bridge,
            config: config,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .transfers,
            listHeaderViewModel: nil,
            isSelectionEnabled: false,
            contentUnavailableViewModelProvider: TransferContentUnavailableProvider(title: emptyStateTitle)
        )

        self.containerViewModel = SearchResultsContainerViewModel(
            bridge: bridge,
            config: config,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: SortHeaderConfig(title: "", options: []),
            headerType: .none,
            initialViewMode: .list,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: {}
        )
    }

    /// Streams this tab's live item count to `onItemCountChange`. The view owns the
    /// task (via `.task`), so cancellation propagates when the tab is dismounted.
    func observeItemCount() async {
        for await count in containerViewModel.itemCountSequence {
            guard !Task.isCancelled else { break }
            onItemCountChange(count)
        }
    }
}
