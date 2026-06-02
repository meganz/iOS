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
    public let completedContainerViewModel: SearchResultsContainerViewModel?
    private let activeSearchResultsViewModel: SearchResultsViewModel?
    private let completedSearchResultsViewModel: SearchResultsViewModel?
    private let inventoryUseCase: (any TransferInventoryUseCaseProtocol)?
    private let filteringUserTransfers: Bool

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
        self.completedContainerViewModel = nil
        self.activeSearchResultsViewModel = nil
        self.completedSearchResultsViewModel = nil
        self.inventoryUseCase = nil
        self.filteringUserTransfers = true
    }

    /// Production initializer. Constructs the registry, the Active and Completed
    /// tab providers, and the `SearchResultsContainerViewModel`s that render them.
    /// Subscribes to each container's item-count sequence so `hasActiveTransfers` /
    /// `hasCompletedTransfers` reflect live state.
    public init(
        inventoryUseCase: some TransferInventoryUseCaseProtocol,
        counterUseCase: some TransferCounterUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        nodeAttributeUseCase: some NodeAttributeUseCaseProtocol,
        filteringUserTransfers: Bool = true
    ) {
        let registry = TransferRegistry()
        self.registry = registry
        self.hasActiveTransfers = false
        self.hasCompletedTransfers = false
        self.hasFailedTransfers = false
        self.inventoryUseCase = inventoryUseCase
        self.filteringUserTransfers = filteringUserTransfers

        let locationResolver = TransferLocationResolver(
            nodeUseCase: nodeUseCase,
            nodeAttributeUseCase: nodeAttributeUseCase
        )

        let activeProvider = TransferSearchResultsProvider(
            filter: .active,
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase,
            registry: registry,
            locationResolver: locationResolver,
            filteringUserTransfers: filteringUserTransfers
        )
        let completedProvider = TransferSearchResultsProvider(
            filter: .completed,
            inventoryUseCase: inventoryUseCase,
            counterUseCase: counterUseCase,
            registry: registry,
            locationResolver: locationResolver,
            filteringUserTransfers: filteringUserTransfers
        )

        let active = Self.makeContainer(provider: activeProvider, registry: registry)
        let completed = Self.makeContainer(provider: completedProvider, registry: registry)
        self.activeSearchResultsViewModel = active.searchResultsViewModel
        self.activeContainerViewModel = active.container
        self.completedSearchResultsViewModel = completed.searchResultsViewModel
        self.completedContainerViewModel = completed.container
    }

    /// Wires a `SearchResultsContainerViewModel` (plus its `SearchResultsViewModel`)
    /// around a transfer provider, reusing the shared registry-backed config. Both
    /// tabs are non-selectable, header-less list views.
    private static func makeContainer(
        provider: some SearchResultsProviding,
        registry: TransferRegistry
    ) -> (container: SearchResultsContainerViewModel, searchResultsViewModel: SearchResultsViewModel) {
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
            resultsProvider: provider,
            bridge: bridge,
            config: config,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .transfers,
            listHeaderViewModel: nil,
            isSelectionEnabled: false,
            contentUnavailableViewModelProvider: TransferContentUnavailableProvider()
        )

        let container = SearchResultsContainerViewModel(
            bridge: bridge,
            config: config,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: SortHeaderConfig(title: "", options: []),
            headerType: .none,
            initialViewMode: .list,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: {}
        )
        return (container, searchResultsViewModel)
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

    public var shouldShowCompletedList: Bool {
        selectedTab == .completed && hasCompletedTransfers && completedContainerViewModel != nil
    }

    /// Seeds Completed presence so the tab bar is correct at launch even before the
    /// Completed tab is opened. A tab's live item count is only available while its
    /// view is mounted, so the inventory is the only source of truth for a user
    /// whose sole transfers are completed ones. Call once on appear.
    public func seedCompletedPresence() {
        guard let inventoryUseCase else { return }
        hasCompletedTransfers = inventoryUseCase
            .completedTransfers(filteringUserTransfers: filteringUserTransfers)
            .contains(where: TransferSearchResultsProvider.isVisibleCompleted)
    }

    /// Observes the item count of the currently-selected tab only. Each tab's data
    /// pipeline is suspended while its container is off-screen, so observing a hidden
    /// tab would only ever yield a frozen value. Scoping to the visible tab matches
    /// the container lifecycle. Drive via `.task(id: selectedTab)` so a tab switch
    /// cancels the previous observation and starts the new one.
    public func observeSelectedTabItemCount() async {
        switch selectedTab {
        case .active: await observeActiveItemCount()
        case .completed: await observeCompletedItemCount()
        case .failed: break // No Failed container yet (future story).
        }
    }

    private func observeActiveItemCount() async {
        guard let activeSearchResultsViewModel else { return }
        for await count in activeSearchResultsViewModel.itemCountSequence {
            hasActiveTransfers = count > 0
            // The Completed pipeline only observes finishes while its tab is mounted.
            // When the last active transfer finishes here on the Active tab, re-seed
            // from inventory so a now-completed transfer keeps the tab bar visible.
            if count == 0 {
                seedCompletedPresence()
            }
        }
    }

    /// Upgrade-only: while the Completed view is mounting, its count sequence emits a
    /// stale 0 before `task()` populates it. Confirming presence on a non-zero count
    /// but never clearing on zero avoids flickering the tab bar during that window
    /// (clearing completed transfers is not yet supported, so the list only grows).
    private func observeCompletedItemCount() async {
        guard let completedSearchResultsViewModel else { return }
        for await count in completedSearchResultsViewModel.itemCountSequence where count > 0 {
            hasCompletedTransfers = true
        }
    }
}
