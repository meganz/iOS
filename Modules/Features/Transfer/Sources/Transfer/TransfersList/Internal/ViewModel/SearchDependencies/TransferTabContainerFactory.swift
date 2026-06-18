import Foundation
import MEGAUIComponent
import MEGAUIKit
import Search

/// Builds the `Search` stack for a single Transfers tab: a
/// `TransferSearchResultsProvider` for `filter`, wrapped in a
/// `SearchResultsContainerViewModel` (a non-selectable, header-less list). Kept in one
/// place so the construction details live with the other Search adapters rather than
/// inside a view model.
@MainActor
enum TransferTabContainerFactory {
    static func make(
        dependency: TransferTabDependency,
        filter: TransferSearchResultsProvider.Filter,
        emptyStateTitle: String
    ) -> SearchResultsContainerViewModel {
        let provider = TransferSearchResultsProvider(
            filter: filter,
            inventoryUseCase: dependency.inventoryUseCase,
            counterUseCase: dependency.counterUseCase,
            registry: dependency.registry,
            locationResolver: dependency.locationResolver,
            finishDateProvider: dependency.finishDateProvider,
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

        return SearchResultsContainerViewModel(
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
}
