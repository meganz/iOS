import Combine
import MEGASwiftUI
import MEGAUIKit
import SwiftUI

@MainActor
public class SearchResultsContainerViewModel: ObservableObject {
    @Published var chipsItems: [ChipViewModel] = []
    @Published var presentedChipsPickerViewModel: ChipViewModel?

    let searchResultsViewModel: SearchResultsViewModel
    public let bridge: SearchBridge
    private let config: SearchConfig

    var colorAssets: SearchConfig.ColorAssets { config.colorAssets }
    var chipAssets: SearchConfig.ChipAssets { config.chipAssets }

    // keep information what were the available chips received with latest
    // results so that we know how to modify the list of chips after
    // selection was changed but we don't have new results
    private var lastAvailableChips: [SearchChipEntity] = []

    private let sortOptionsViewModel: SearchResultsSortOptionsViewModel

    var displaySortOptionsViewModel: SearchResultsSortOptionsViewModel {
        let displaySortOptions = sortOptionsViewModel.sortOptions.compactMap { sortOption -> SearchResultsSortOption? in
            let currentSortOrder = searchResultsViewModel.currentQuery.sorting
            guard currentSortOrder != sortOption.sortOrder else { return nil }
            guard currentSortOrder.key != sortOption.sortOrder.key else { return sortOption }
            guard sortOption.sortOrder.direction != .descending else { return nil }
            return sortOption.removeIcon()
        }
        return sortOptionsViewModel.makeNewViewModel(with: displaySortOptions) { [weak self] in
            // Selection is sort option already but it might not contain the icon.
            // So need to get the original sort option which contains the icon.
            guard let self,
                  let option = $0.currentDirectionIcon == nil ? sortOption(for: $0.sortOrder) : $0 else {
                return
            }

            selectedSortOption(option)
        }
    }

    lazy var sortHeaderViewModel: SearchResultsHeaderSortViewViewModel = {
        let sortOptions = sortOptionsViewModel.sortOptions
        assert(sortOptions.isNotEmpty, "Sort options should not be empty")
        let sortOption = sortOptions
            .first(where: { $0.sortOrder == searchResultsViewModel.currentQuery.sorting }) ?? sortOptions[0]
        return .init(selectedOption: sortOption, displaySortOptionsViewModel: displaySortOptionsViewModel)
    }()

    let viewModeHeaderViewModel: SearchResultsHeaderViewModeViewModel
    @Published public private(set) var showChips: Bool = false
    @Published public var showSorting: Bool = false
    private var subscriptions: Set<AnyCancellable> = []
    private let shouldShowMediaDiscoveryModeHandler: () -> Bool

    public init(
        bridge: SearchBridge,
        config: SearchConfig,
        searchResultsViewModel: SearchResultsViewModel,
        sortOptionsViewModel: SearchResultsSortOptionsViewModel,
        showChips: Bool,
        initialViewMode: SearchResultsViewMode,
        shouldShowMediaDiscoveryModeHandler: @escaping () -> Bool
    ) {
        self.bridge = bridge
        self.config = config
        self.searchResultsViewModel = searchResultsViewModel
        self.sortOptionsViewModel = sortOptionsViewModel
        self.showChips = showChips
        self.shouldShowMediaDiscoveryModeHandler = shouldShowMediaDiscoveryModeHandler

        let availableViewModes: [SearchResultsViewMode] = Self.modes(using: shouldShowMediaDiscoveryModeHandler)
        assert(
            availableViewModes.contains(initialViewMode),
            "Initial view mode \(initialViewMode) is not in available modes \(availableViewModes)"
        )
        self.viewModeHeaderViewModel = .init(
            selectedViewMode: Self.validated(initialViewMode, in: availableViewModes),
            availableViewModes: availableViewModes
        )

        viewModeHeaderViewModel
            .$selectedViewMode
            .sink {
                bridge.viewModeChanged($0)
            }
            .store(in: &subscriptions)
        self.searchResultsViewModel.interactor = self
    }

    func task() async {
        await searchResultsViewModel.task()
    }

    func showChipsGroupPicker(with id: String) {
        guard let index = chipsItems.firstIndex(where: { $0.id == id }) else { return }
        presentedChipsPickerViewModel = chipsItems[index]
    }

    func dismissChipGroupPicker() async {
        presentedChipsPickerViewModel = nil
    }

    private func selectedSortOption(_ sortOption: SearchResultsSortOption) {
        sortHeaderViewModel.selectionChanged(to: sortOption)
        bridge.updateSortOrder(sortOption.sortOrder)

        Task {
            await searchResultsViewModel.queryChanged(with: sortOption.sortOrder)
            updateDisplaySortOptions()
        }
    }

    private func updateDisplaySortOptions() {
        sortHeaderViewModel.displaySortOptionsViewModel = displaySortOptionsViewModel
    }

    private func title(for chip: SearchChipEntity, appliedChips: [SearchChipEntity]) -> String {
        if chip.subchips.isNotEmpty,
           let selectedChip = chip.subchips.first(where: { subchip in
               appliedChips.contains(where: { subchip.id == $0.id })
           }) {
            return selectedChip.title
        } else {
            return chip.title
        }
    }

    private func tapped(_ chip: SearchChipEntity) async {
        let query = Self.makeQueryAfter(tappedChip: chip, currentQuery: searchResultsViewModel.currentQuery)
        // updating chips here as well to make selection visible before results are returned
        updateChipsFrom(appliedChips: query.chips)
        await searchResultsViewModel.showLoadingPlaceholderIfNeeded()
        await searchResultsViewModel.queryChanged(to: query)
        bridge.chip(tapped: chip, isSelected: query.chips.contains(chip))
    }

    private func selected(for chip: SearchChipEntity, appliedChips: [SearchChipEntity]) -> Bool {
        if chip.subchips.isNotEmpty {
            chip.subchips.filter { subchip in
                appliedChips.contains(where: { $0.type.isInSameChipGroup(as: subchip.type) })
            }.isNotEmpty
        } else {
            appliedChips.contains(chip)
        }
    }

    private func icon(for chip: SearchChipEntity, selected: Bool) -> PillView.Icon {
        if chip.subchips.isNotEmpty {
            .trailing(Image(systemName: "chevron.down"))
        } else {
            selected ? .leading(Image(systemName: "checkmark")) : .none
        }
    }

    private func updateChipsFrom(appliedChips: [SearchChipEntity]) {
        let updatedChips = lastAvailableChips.map { chip in
            let subchips = subchipsFrom(appliedChips: appliedChips, allChips: chip.subchips)
            let selected = selected(for: chip, appliedChips: appliedChips)

            return ChipViewModel(
                id: chip.id,
                pill: .init(
                    title: title(for: chip, appliedChips: appliedChips),
                    selected: selected,
                    icon: icon(for: chip, selected: selected),
                    config: config.chipAssets
                ),
                subchips: subchips,
                subchipsPickerTitle: chip.subchipsPickerTitle,
                selectionIndicatorImage: selected ? config.chipAssets.selectionIndicatorImage : nil,
                selected: selected,
                select: { [weak self] in
                    guard let self else { return }
                    if chip.subchips.isEmpty {
                        await dismissChipGroupPicker()
                        await tapped(chip)
                    } else {
                        showChipsGroupPicker(with: chip.id)
                    }
                }
            )
        }

        updateChipsItems(with: updatedChips)
    }

    private func updateChipsItems(with chipViewModels: [ChipViewModel]) {
        chipsItems = chipViewModels
    }

    private func subchipsFrom(
        appliedChips: [SearchChipEntity],
        allChips: [SearchChipEntity]
    ) -> [ChipViewModel] {
        allChips.map { chip in
            let selected = appliedChips.contains(where: { $0.id == chip.id })
            return ChipViewModel(
                id: chip.id,
                pill: .init(
                    title: chip.title,
                    selected: selected,
                    icon: selected ? .leading(Image(systemName: "checkmark")) : .none,
                    config: config.chipAssets
                ),
                selectionIndicatorImage: selected ? config.chipAssets.selectionIndicatorImage : nil,
                selected: selected,
                select: { [weak self] in
                    await self?.dismissChipGroupPicker()
                    await self?.tapped(chip)
                }
            )
        }
    }

    private func refreshViewModeOptions() {
        let availableViewModes: [SearchResultsViewMode] = Self.modes(using: shouldShowMediaDiscoveryModeHandler)
        guard viewModeHeaderViewModel.availableViewModes != availableViewModes else { return }
        viewModeHeaderViewModel.availableViewModes = availableViewModes

        if availableViewModes.notContains(viewModeHeaderViewModel.selectedViewMode) {
            assertionFailure("The selected view mode is not present in the list of available view modes")
            viewModeHeaderViewModel.selectedViewMode = Self.validated(.list, in: availableViewModes)
        }
    }

    private static func modes(using handler: () -> Bool) -> [SearchResultsViewMode] {
        handler() ? [.list, .grid, .mediaDiscovery] : [.list, .grid]
    }

    private static func validated(_ preferred: SearchResultsViewMode, in modes: [SearchResultsViewMode]) -> SearchResultsViewMode {
        modes.contains(preferred) ? preferred : (modes.contains(.list) ? .list : modes.first ?? preferred)
    }

    private func sortOption(for sortOrder: Search.SortOrderEntity) -> SearchResultsSortOption? {
        sortOptionsViewModel
            .sortOptions
            .first(where: { $0.sortOrder == sortOrder })
    }

    // create new query by deselecting previously selected chips
    // and selected new one
    static func makeQueryAfter(
        tappedChip: SearchChipEntity,
        currentQuery: SearchQuery
    ) -> SearchQuery {
        let modifyChips: (SearchChipEntity) -> [SearchChipEntity] = { chip in
            var chips: [SearchChipEntity] = currentQuery.chips

            if let existingChipIndex = chips.firstIndex(where: { $0.id == chip.id }) {
                chips.remove(at: existingChipIndex)
            } else {
                if let index = chips.firstIndex(where: { $0.type.isInSameChipGroup(as: chip.type) }) {
                    chips.remove(at: index)
                }
                chips.append(chip)
            }

            return chips
        }

        return .userSupplied(
            .init(
                query: currentQuery.query,
                sorting: currentQuery.sorting,
                mode: currentQuery.mode,
                isSearchActive: currentQuery.isSearchActive,
                chips: modifyChips(tappedChip)
            )
        )
    }
}

extension SearchResultsContainerViewModel: SearchResultsInteractor {
    func resetLastAvailableChips() {
        lastAvailableChips = []
    }

    func updateQuery(_ currentQuery: SearchQuery) async -> SearchQuery {
        if !showChips {
            currentQuery.clearingChips()
        } else {
            await currentQuery.withUpdatedSortOrder(bridge.sortingOrder())
        }
    }

    func consume(results: SearchResultsEntity) {
        lastAvailableChips = results.availableChips
        updateChipsFrom(appliedChips: results.appliedChips)
    }

    func listItemsUpdated(_ items: [SearchResultRowViewModel]) {
        showSorting = items.isNotEmpty
        refreshViewModeOptions()
    }

    var currentViewMode: SearchResultsViewMode {
        viewModeHeaderViewModel.selectedViewMode
    }
}

public extension SearchResultsContainerViewModel {
    var selectedResultsCount: Int {
        searchResultsViewModel.selectedResultIds.count
    }

    func setSearchChipsVisible(_ visible: Bool, animated: Bool = true) {
        if animated {
            withAnimation { showChips = visible }
        } else {
            showChips = visible
        }
    }

    func searchActiveDidChange(_ isActive: Bool) {
        setSearchChipsVisible(isActive)
        if isActive {
            searchResultsViewModel.forceListLayout()
        } else {
            searchResultsViewModel.resetForcedListLayout()
        }
    }

    @discardableResult
    func changeSortOrder(_ sortOrder: SortOrderEntity) -> Task<Void, Never> {
        Task { @MainActor in
            await searchResultsViewModel.showLoadingPlaceholderIfNeeded()
            await searchResultsViewModel.queryChanged(with: sortOrder)
        }
    }

    func update(pageLayout: PageLayout) {
        searchResultsViewModel.layout = pageLayout
        viewModeHeaderViewModel.selectedViewMode = pageLayout.toSearchResultsViewMode()
    }

    func setEditing(_ editing: Bool) {
        searchResultsViewModel.editing = editing
    }

    func clearSelection() {
        searchResultsViewModel.clearSelection()
    }

    func selectSearchResults(_ results: [SearchResult]) {
        searchResultsViewModel.selectSearchResults(results)
    }

    func toggleSelectAll() {
        searchResultsViewModel.toggleSelectAll()
    }
}
