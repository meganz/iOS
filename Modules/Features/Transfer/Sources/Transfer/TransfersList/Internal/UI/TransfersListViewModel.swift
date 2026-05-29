import Foundation
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search

@MainActor
public final class TransfersListViewModel: ObservableObject {
    @Published public var selectedTab: TransfersTab = .active

    @Published public private(set) var hasActiveTransfers: Bool
    @Published public private(set) var hasCompletedTransfers: Bool
    @Published public private(set) var hasFailedTransfers: Bool

    private let registry: TransferRegistry
    public let activeContainerViewModel: SearchResultsContainerViewModel?
    private let searchResultsViewModel: SearchResultsViewModel?

    public init(
        hasActiveTransfers: Bool = false,
        hasCompletedTransfers: Bool = false,
        hasFailedTransfers: Bool = false
    ) {
        self.hasActiveTransfers = hasActiveTransfers
        self.hasCompletedTransfers = hasCompletedTransfers
        self.hasFailedTransfers = hasFailedTransfers
        self.registry = TransferRegistry()
        self.activeContainerViewModel = nil
        self.searchResultsViewModel = nil
    }

    /// Production initializer. Constructs the registry, the Active tab provider,
    /// and the `SearchResultsContainerViewModel` that renders it. Subscribes to
    /// the container's item-count sequence so `hasActiveTransfers` reflects live
    /// state.
    public init(
        inventoryUseCase: some TransferInventoryUseCaseProtocol,
        counterUseCase: some TransferCounterUseCaseProtocol,
        filteringUserTransfers: Bool = true
    ) {
        let registry = TransferRegistry()
        self.registry = registry
        self.hasActiveTransfers = false
        self.hasCompletedTransfers = false
        self.hasFailedTransfers = false

        let activeProvider = TransferSearchResultsProvider(
            filter: .active,
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase,
            registry: registry,
            filteringUserTransfers: filteringUserTransfers
        )

        let bridge = SearchBridge(
            selection: { _ in },
            context: { _, _ in
                // Per-row primary action (pause/resume/vertical dots)
            },
            chipTapped: { _, _ in },
            sortingOrder: { .init(key: .name) },
            updateSortOrder: { _ in },
            chipPickerShowedHandler: { _ in }
        )

        let config = SearchConfig.transfers(registry: registry)

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: activeProvider,
            bridge: bridge,
            config: config,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .transfers,
            listHeaderViewModel: nil,
            isSelectionEnabled: false,
            contentUnavailableViewModelProvider: TransferContentUnavailableProvider()
        )
        self.searchResultsViewModel = searchResultsViewModel

        self.activeContainerViewModel = SearchResultsContainerViewModel(
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

    public var hasAnyTransfers: Bool {
        hasActiveTransfers || hasCompletedTransfers || hasFailedTransfers
    }

    public var emptyStateLabel: String {
        guard hasAnyTransfers else {
            return Strings.Localizable.Transfers.EmptyState.noTransfers
        }
        switch selectedTab {
        case .active: return Strings.Localizable.Transfers.EmptyState.noActiveTransfers
        case .completed: return Strings.Localizable.Transfers.EmptyState.noCompletedTransfers
        case .failed: return Strings.Localizable.Transfers.EmptyState.noFailedTransfers
        }
    }

    public var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .active: !hasActiveTransfers
        case .completed: !hasCompletedTransfers
        case .failed: !hasFailedTransfers
        }
    }

    /// True when the Active tab should host the live list. Currently equivalent to
    /// `selectedTab == .active && hasActiveTransfers`, but kept as a derived property
    /// so future stories can add gating without rippling the view.
    public var shouldShowActiveList: Bool {
        selectedTab == .active && hasActiveTransfers && activeContainerViewModel != nil
    }

    public func observeActiveItemCount() async {
        guard let searchResultsViewModel else { return }
        for await count in searchResultsViewModel.itemCountSequence {
            hasActiveTransfers = count > 0
        }
    }
}
