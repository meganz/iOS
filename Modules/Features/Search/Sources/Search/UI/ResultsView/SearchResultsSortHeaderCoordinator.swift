import Foundation

@MainActor
public final class SearchResultsSortHeaderCoordinator {
    private let sortOptionsViewModel: SearchResultsSortOptionsViewModel

    private let currentSortOrderProvider: () -> SortOrderEntity
    private let sortOptionSelectionHandler: @MainActor (SearchResultsSortOption) async -> Void
    private let hiddenSortOptionKeysProvider: () -> Set<SortOrderEntity.Key>
    private var selectionTask: Task<Void, Never>?

    public lazy var headerViewModel: SearchResultsHeaderSortViewViewModel = {
        let sortOptions = sortOptionsViewModel.sortOptions
        assert(sortOptions.isNotEmpty, "Sort options should not be empty")
        let sortOption = sortOptions
            .first(where: { $0.sortOrder == currentSortOrderProvider() }) ?? sortOptions[0]
        return .init(selectedOption: sortOption, displaySortOptionsViewModel: displaySortOptionsViewModel)
    }()

    var displaySortOptionsViewModel: SearchResultsSortOptionsViewModel {
        let currentSortOrder = currentSortOrderProvider()
        let keysToHide = hiddenSortOptionKeysProvider()

        let displaySortOptions = sortOptionsViewModel.sortOptions.compactMap { sortOption -> SearchResultsSortOption? in
            // Rules:
            // - Hide keys in `keysToHide`
            // - Hide the currently selected sort (same key + direction)
            // - If same key but different direction, show that option with its icon
            // - For other keys, show only ascending options and strip their icons
            guard keysToHide.notContains(sortOption.sortOrder.key) else { return nil }
            guard currentSortOrder != sortOption.sortOrder else { return nil }
            guard currentSortOrder.key != sortOption.sortOrder.key else { return sortOption }
            guard sortOption.sortOrder.direction != .descending else { return nil }
            return sortOption.removeIcon()
        }
        return sortOptionsViewModel.makeNewViewModel(with: displaySortOptions) { [weak self] in
            // Selection is sort option already but it might not contain the icon.
            // So need to get the original sort option which contains the icon.
            guard let self, let option = $0.currentDirectionIcon == nil ? sortOption(for: $0.sortOrder) : $0 else {
                return
            }

            selectionChanged(to: option)
            selectionTask?.cancel()
            selectionTask = Task {
                await sortOptionSelectionHandler(option)
                updateDisplaySortOptions()
            }
        }
    }

    public init(
        sortOptionsViewModel: SearchResultsSortOptionsViewModel,
        currentSortOrderProvider: @escaping () -> SortOrderEntity,
        sortOptionSelectionHandler: @escaping @MainActor (SearchResultsSortOption) async -> Void,
        hiddenSortOptionKeysProvider: @escaping () -> Set<SortOrderEntity.Key> = { [] }
    ) {
        self.sortOptionsViewModel = sortOptionsViewModel
        self.currentSortOrderProvider = currentSortOrderProvider
        self.sortOptionSelectionHandler = sortOptionSelectionHandler
        self.hiddenSortOptionKeysProvider = hiddenSortOptionKeysProvider
    }

    deinit {
        selectionTask?.cancel()
    }

    private func updateDisplaySortOptions() {
        headerViewModel.displaySortOptionsViewModel = displaySortOptionsViewModel
    }

    public func updateSortUI() {
        guard let sortOption = sortOption(for: currentSortOrderProvider()) else { return }
        headerViewModel.selectionChanged(to: sortOption)
        updateDisplaySortOptions()
    }

    private func selectionChanged(to sortOption: SearchResultsSortOption) {
        headerViewModel.selectionChanged(to: sortOption)
    }

    private func sortOption(for sortOrder: SortOrderEntity) -> SearchResultsSortOption? {
        sortOptionsViewModel
            .sortOptions
            .first(where: { $0.sortOrder == sortOrder })
    }
}
