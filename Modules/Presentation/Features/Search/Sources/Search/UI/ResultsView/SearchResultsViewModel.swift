import Combine
import MEGAFoundation
import MEGASwift
import MEGASwiftUI
import MEGAUIKit
import SwiftUI

@MainActor
public class SearchResultsViewModel: ObservableObject {
    @Published var listItems: [SearchResultRowViewModel]  = []
    @Published var bottomInset: CGFloat = 0.0
    @Published var emptyViewModel: ContentUnavailableViewModel?
    @Published var isLoadingPlaceholderShown = false

    // this will need to be to exposed outside when parent will need to know exactly what is selected
    @Published var selectedResultIds: Set<ResultId> = []

    @Published public var layout: PageLayout

    @Published var chipsItems: [ChipViewModel] = []
    @Published var presentedChipsPickerViewModel: ChipViewModel?

    @Published var selectedRowIds = Set<SearchResultRowViewModel.ID>()

    var fileListItems: [SearchResultRowViewModel] {
        listItems.filter { $0.result.thumbnailDisplayMode == .vertical }
    }

    var folderListItems: [SearchResultRowViewModel] {
        listItems.filter { $0.result.thumbnailDisplayMode == .horizontal }
    }

    var colorAssets: SearchConfig.ColorAssets {
        config.colorAssets
    }

    var chipAssets: SearchConfig.ChipAssets {
        config.chipAssets
    }

    var containsSwipeActions: Bool {
        listItems.first?.swipeActions.isNotEmpty ?? false
    }

    // this is needed to be able to construct new query after receiving new query string from SearchBar
    private var currentQuery: SearchQuery = .initial

    // keep information what were the available chips received with latest
    // results so that we know how to modify the list of chips after
    // selection was changed but we don't have new results
    private var lastAvailableChips: [SearchChipEntity] = []

    // do not perform initial load when coming back from the pushed vc
    private var initialLoadDone = false

    private var miniPlayerBottomInset: CGFloat = 0.0
    private var subscriptions = Set<AnyCancellable>()

    // communication back and forth to the parent and searchbar
    public let bridge: SearchBridge
    
    // current task that needs to be cancelled when we modify
    // query string or selected chips while previous search is being
    // executed
    private var searchingTask: Task<Void, any Error>?

    // Debounce the search for 0.5 seconds after the user stops typing in the search input
    private var debounceTask: Task<Void, any Error>?

    // this flag is used to indicate whether the data has been loaded for every triggered search
    
    @Atomic private var areNewSearchResultsLoaded = false

    // data source for the results (result list, chips)
    private let resultsProvider: any SearchResultsProviding

    private let config: SearchConfig

    // delay after we should display loading placeholder, in seconds
    private let showLoadingPlaceholderDelay: Double

    // delay after which we trigger searching after the user stops typing, in seconds
    private let searchInputDebounceDelay: Double

    private let keyboardVisibilityHandler: any KeyboardVisibilityHandling

    private let viewDisplayMode: ViewDisplayMode

    @Published public var editing: Bool = false

    private var selectedRowsSubscription: AnyCancellable?

    private let updatedSearchResultsPublisher: BatchingPublisher<SearchResultUpdateSignal>

    private let isSearchByNodeTagsFeatureEnabled: Bool

    let listHeaderViewModel: ListHeaderViewModel?

    // Specifies whether the results are selectable or not.
    let isSelectionEnabled: Bool

    public init(
        resultsProvider: any SearchResultsProviding,
        bridge: SearchBridge,
        config: SearchConfig,
        layout: PageLayout,
        showLoadingPlaceholderDelay: Double = 1,
        searchInputDebounceDelay: Double = 0.5,
        keyboardVisibilityHandler: any KeyboardVisibilityHandling,
        viewDisplayMode: ViewDisplayMode,
        updatedSearchResultsPublisher: BatchingPublisher<SearchResultUpdateSignal> = BatchingPublisher(interval: 1), // Emits search result updates as a batch every 1 seconds
        isSearchByNodeTagsFeatureEnabled: Bool,
        listHeaderViewModel: ListHeaderViewModel?,
        isSelectionEnabled: Bool
    ) {
        self.resultsProvider = resultsProvider
        self.bridge = bridge
        self.config = config
        self.showLoadingPlaceholderDelay = showLoadingPlaceholderDelay
        self.searchInputDebounceDelay = searchInputDebounceDelay
        self.keyboardVisibilityHandler = keyboardVisibilityHandler
        self.viewDisplayMode = viewDisplayMode
        self.layout = layout
        self.updatedSearchResultsPublisher = updatedSearchResultsPublisher
        self.isSearchByNodeTagsFeatureEnabled = isSearchByNodeTagsFeatureEnabled
        self.listHeaderViewModel = listHeaderViewModel
        self.isSelectionEnabled = isSelectionEnabled
        self.bridge.queryChanged = { [weak self] query  in
            let _self = self
            
            _self?.debounceTask?.cancel()
            _self?.debounceTask = Task {
                try await Task.sleep(nanoseconds: UInt64(searchInputDebounceDelay*1_000_000_000))

                if Task.isCancelled { return }
                await _self?.showLoadingPlaceholderIfNeeded()
                await _self?.queryChanged(to: query, isSearchActive: true)
            }
        }

        self.bridge.queryCleaned = { [weak self] in
            let _self = self
            Task { await _self?.queryCleaned() }
        }
        
        self.bridge.searchCancelled = { [weak self] in
            let _self = self
            Task { await _self?.searchCancelled() }
        }
        
        self.bridge.layoutChanged = { [weak self] layout in
            self?.layout = layout
        }
        
        self.bridge.updateBottomInset = { [weak self] inset in
            self?.miniPlayerBottomInset = inset
            self?.bottomInset = inset
        }

        self.bridge.editingCancelled = { [weak self] in
            self?.editing = false
        }

        setupKeyboardVisibilityHandling()

        selectedRowsSubscription = $selectedRowIds
            .removeDuplicates()
            .dropFirst()
            .throttle(for: .seconds(0.4), scheduler: DispatchQueue.main, latest: true)
            .scan((Set<SearchResultRowViewModel.ID>(), Set<SearchResultRowViewModel.ID>())) { previous, current in
                // We want only the items that are selected or deselected from the set.
                // Hence we store the previous value and find out the difference.
                return (Set(current), previous.0.symmetricDifference(Set(current)))
            }.sink { [weak self] (_, result) in
                guard let self else { return }
                let rowsRemoved = result.filter { self.selectedRowIds.notContains($0) }
                let rowsAdded = result.filter { self.selectedRowIds.contains($0) }
                
                let idsRemoved = listItems.filter { rowsRemoved.contains($0.id) }.map { $0.result.id }
                let idsAdded = listItems.filter { rowsAdded.contains($0.id) }.map { $0.result.id }
                
                if idsAdded.isNotEmpty {
                    selectedResultIds.formUnion(idsAdded)
                }
                
                if idsRemoved.isNotEmpty {
                    selectedResultIds.subtract(idsRemoved)
                }
                
                bridge.selectionChanged(selectedResultIds)
            }

        updatedSearchResultsPublisher
                    .publisher
                    .sink(receiveValue: { @Sendable [weak self] signals in
                        Task { @MainActor in
                            self?.searchResultsUpdated(signals)
                        }
                    })
                    .store(in: &subscriptions)
        observeListItemsUpdate()
    }

    /// meant called to be called in the SwiftUI View's .task modifier
    /// which means task is called on the appearance and cancelled on disappearance
    func task() async {
        await performInitialSearchOrRefresh()
        await startMonitoringResults()
    }
    
    func performInitialSearchOrRefresh() async {
        // We need to check if listItems is empty  because after first load of the screen, the listItems will be filled with data,
        // so there is no need for additional query which will only cause flicker when we quickly go in and out of this screen
        guard !initialLoadDone, listItems.isEmpty else {
            // perform refreshing search results on appear to get updated one.
            // because when we from some screen which may trigger changes to the search results
            // for example: go to settings to toggle the `Show Hidden Nodes` setting,
            // we expect the search result to show/not show hidden nodes according to the changed setting
            try? await refreshSearchResults()
            return
        }
        initialLoadDone = true
        await defaultSearchQuery()
    }
    
    /// To be called on a separate `.task` modifier from the client View to get the benefit of task cancellation upon appearing/disappearing
    func startMonitoringResults() async {
        for await updateSignal in resultsProvider.searchResultUpdateSignalSequence() {
            guard !Task.isCancelled else { break }
            
            // Use of publisher also attempts to fix crash issue SAO-1916
            updatedSearchResultsPublisher.append(updateSignal)
        }
    }
    
    private func defaultSearchQuery() async {
        // when screen is presented first time,
        // do an initial search that lists contents of the directory
        // This is using a different method in the SDK
        // hence an enum is needed to reliably tell the difference
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: updatedQuery(with: await bridge.sortingOrder()))
    }
    
    private func cancelSearchTask() {
        searchingTask?.cancel()
    }

    private func cancelDebounceTask() {
        debounceTask?.cancel()
    }

    func queryCleaned() async {
        // clearing query in the search bar
        // this should reset just query string but keep chips etc
        cancelDebounceTask()
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: "", isSearchActive: false)
    }
    
    func scrolled() {
        if searchingTask == nil {
            bridge.resignKeyboard()
        }
    }

    func searchCancelled() async {
        // cancel button on the search bar was tapped
        // clear items, chips, initialLoadDone so that we load fresh
        // data when view appears again
        initialLoadDone = false
        handleEditingChanged(false)
        currentQuery = .initial
        clearSearchResults()
        lastAvailableChips = []
        selectedResultIds = []
        await defaultSearchQuery()
    }
    
    func queryChanged(to query: String, isSearchActive: Bool) async {
        await queryChanged(
            to: .userSupplied(
                Self.makeQueryUsing(
                    string: query, isSearchActive: isSearchActive, current: currentQuery
                )
            )
        )
    }

    // After the user triggered new search query, if the results don't come in more than 1 second
    // we should display the shimmer placeholder while the search results loading finishes
    // If the search results are already loaded -> areNewSearchResultsLoaded = true, we shouldn't display shimmer loading
    func showLoadingPlaceholderIfNeeded() async {
        Task {
            try await Task.sleep(nanoseconds: UInt64(showLoadingPlaceholderDelay*1_000_000_000))
            guard !(areNewSearchResultsLoaded) else { return }
            updateLoadingPlaceholderVisibility(true)
        }
    }

    private func queryChanged(to query: SearchQuery) async {
        cancelSearchTask()
        cancelDebounceTask()

        // we need to store query to know what chips are selected
        currentQuery = query

        clearSearchResults()

        searchingTask = Task {
            await performSearch(using: query)
        }
        
        try? await searchingTask?.value
    }
    
    private func performSearch(
        using query: SearchQuery,
        lastItemIndex: Int? = nil
    ) async {
        if lastItemIndex == nil {
            updateSearchResultsLoaded(false)
        }

        if Task.isCancelled { return }
        
        let results = await resultsProvider.search(queryRequest: query, lastItemIndex: lastItemIndex)

        if Task.isCancelled { return }
        
        guard let results else { return }

        if lastItemIndex == nil {
            clearSearchResults()
        }

        await prepareResults(results, query: query)
    }

    private func loadMoreIfNeeded(item: SearchResultRowViewModel) async {
        switch layout {
        case .list:
            guard let index = listItems.firstIndex(where: { $0.id == item.id }) else { return }
            await loadMoreIfNeeded(at: index)
        case .thumbnail:
            await loadMoreIfNeededThumbnailMode(item: item)
        }
    }
    
    private func loadMoreIfNeeded(at index: Int) async {
        // Note: Even if the `index` is not close to the end of the result, we still call `performSearch`,
        // The `resultsProvider` will take care of the outcome by returing nil for the indexes that aren't supposed to
        // trigger the `load more` process.
        await performSearch(using: currentQuery, lastItemIndex: index)
    }
    
    private func loadMoreIfNeededThumbnailMode(item: SearchResultRowViewModel) async {
        let isFileItem = item.result.thumbnailDisplayMode == .vertical
        
        if isFileItem {
            guard let index = fileListItems.firstIndex(where: { $0.id == item.id }) else { return }
            // In thumbnail mode, we first display `folderListItems` and then `fileListItems` (check the `thumbnailContent` in `SearchResultsView`)
            // It means the index of file item in the view is equal to its index in `fileListItems` plus number of items in `folderListItems`
            // For example: Let's say we 20 folders and 5 files, then the index of file item in the view should start from 21 which are 21, 22, 23, 24, 25.
            await loadMoreIfNeeded(at: index + folderListItems.count)
        } else {
            guard let index = folderListItems.firstIndex(where: { $0.id == item.id }) else { return }
            await loadMoreIfNeeded(at: index)
        }
    }
    
    func onItemAppear(_ item: SearchResultRowViewModel) async {
        await loadMoreIfNeeded(item: item)
    }

    private func prepareResults(_ results: SearchResultsEntity, query: SearchQuery) async {
        let items = results.results.map { result in
            mapSearchResultToViewModel(result)
        }

        await consume(results, items: items, query: query)
    }

    private func mapSearchResultToViewModel(_ result: SearchResult) -> SearchResultRowViewModel {
        let content = config.contextPreviewFactory.previewContentForResult(result)
        let swipeActions = result.swipeActions(viewDisplayMode)
        return SearchResultRowViewModel(
            result: result,
            query: { [weak self] in
                self?.currentQuery.query
            },
            rowAssets: config.rowAssets,
            colorAssets: config.colorAssets,
            previewContent: .init(
                actions: content.actions.map({ action in
                    return .init(
                        title: action.title,
                        imageName: action.imageName,
                        handler: { [weak self] in
                            Task { @MainActor in
                                self?.actionPressedOn(result)
                                action.handler()
                            }
                        }
                    )
                }),
                previewMode: content.previewMode
            ),
            actions: rowActions(for: result),
            swipeActions: swipeActions,
            shouldShowMatchingTags: isSearchByNodeTagsFeatureEnabled
        )
    }

    private func actionPressedOn(_ result: SearchResult) {
        if !editing {
            handleEditingChanged(true)
        }

        if let selectedRow = rowViewModel(for: result) {
            toggleSelected(selectedRow)
        }
    }

    func handleEditingChanged(_ isEditing: Bool) {
        editing = isEditing
        bridge.editingChanged(isEditing)
    }

    // The total number of columns we should display is calculated based on how many columns
    // with the columnWidth can fit in the current width of the screen
    // If the number of columns we calculate is less than 2, we should always
    // display minimum of 2 columns
    func columns(_ screenWidth: CGFloat) -> [GridItem] {
        let columnWidth = 180
        let horizontalPadding: CGFloat = 16

        let containerWidth = screenWidth - horizontalPadding

        let columnCount = max(2, Int(containerWidth) / columnWidth)

        return Array(
            repeating: .init(.flexible()),
            count: columnCount
        )
    }

    private func searchResultsUpdated(_ signals: [SearchResultUpdateSignal]) {
        // Any possible ongoing searching task is no longer relevant upon result updates,
        // it should be replaced with the refreshing task
        cancelSearchTask()
        searchingTask = Task { [weak self] in
            guard let self, !Task.isCancelled else { return }
            switch SearchResultsUpdateManager(signals: signals).processSignals() {
            case .generic:
                try await refreshSearchResults()
            case .specificUpdateResults(let results):
                await searchResultsUpdated(results)
            case .none:
                break
            }
        }
    }

    private func rowViewModel(for result: SearchResult) -> SearchResultRowViewModel? {
        listItems.first { $0.result.id == result.id }
    }

    private func toggleSelected(_ row: SearchResultRowViewModel) {
        let rowId = row.id
        if selectedRowIds.contains(rowId) {
            selectedRowIds.remove(rowId)
        } else {
            selectedRowIds.insert(rowId)
        }
    }
    
    private func selectionFor(result: SearchResult) -> SearchResultSelection {
        .init(
            result: result,
            siblingsProvider: { [weak self] in
                self?.resultsProvider.currentResultIds() ?? []
            }
        )
    }
    
    private func rowActions(for result: SearchResult) -> SearchResultRowViewModel.UserActions {
        let selection = selectionFor(result: result)
        return .init(
            contextAction: { [weak self] button in
                // we pass in button to show popover attached to the correct view
                self?.bridge.context(result, button)
            },
            selectionAction: { [weak self] in
                guard let self else { return }
                if editing {
                    if let selectedRow = rowViewModel(for: result) {
                        toggleSelected(selectedRow)
                    }
                } else {
                    bridge.selection(selection)
                }
            },
            previewTapAction: { [weak self] in
                self?.bridge.selection(selection)
            }
        )
    }

    func consume(
        _ results: SearchResultsEntity,
        items: [SearchResultRowViewModel],
        query: SearchQuery
    ) async {
        if Task.isCancelled { return }
        updateSearchResultsLoaded(true)
        updateLoadingPlaceholderVisibility(false)

        lastAvailableChips = results.availableChips
        await updateChipsFrom(appliedChips: results.appliedChips)
        
        let selectedItems = items
            .filter { selectedResultIds.contains($0.result.id) }
        
        Task {
            self.listItems.append(contentsOf: items)
            
            selectedRowIds.formUnion(selectedItems.map { $0.id })
            
            if #available(iOS 16.0, *) {
                withAnimation {
                    emptyViewModel = Self.makeEmptyView(
                        whenListItems: listItems.isEmpty,
                        query: query,
                        appliedChips: results.appliedChips,
                        config: config
                    )
                }
            } else {
                emptyViewModel = Self.makeEmptyView(
                    whenListItems: listItems.isEmpty,
                    query: query,
                    appliedChips: results.appliedChips,
                    config: config
                )
            }
        }
    }
    
    private static func makeEmptyView(
        whenListItems empty: Bool,
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel? {
        guard empty else { return nil }

        // we show contextual, chip-related empty screen only when there
        // is not text query
        if query.query.isEmpty {
            // node format takes priority when showing empty assets.
            let chip = appliedChips.first { $0.type.isNodeFormatChip || $0.type.isNodeTypeChip } ?? appliedChips.first

            // this assumes only one chip at most can be applied at any given time
            return config.emptyViewAssetFactory(chip, query).emptyViewModel
        }
        
        // when there is non-empty text query (and no results of course) ,
        // [independently if there is any chip selected
        // we show generic 'no results' empty screen
        return config.emptyViewAssetFactory(nil, query).emptyViewModel
    }
    
    private func tapped(_ chip: SearchChipEntity) async {
        let query = Self.makeQueryAfter(tappedChip: chip, currentQuery: currentQuery)
        // updating chips here as well to make selection visible before results are returned
        await updateChipsFrom(appliedChips: query.chips)
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: query)
        bridge.chip(tapped: chip, isSelected: query.chips.contains(chip))
    }

    private func updateChipsFrom(appliedChips: [SearchChipEntity]) async {
        let updatedChips = lastAvailableChips.map { chip in
            let subchips = subchipsFrom(appliedChips: appliedChips, allChips: chip.subchips)
            let selected = selected(for: chip, appliedChips: appliedChips)

            return ChipViewModel(
                id: chip.title,
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
                    if chip.subchips.isEmpty {
                        await self?.dismissChipGroupPicker()
                        await self?.tapped(chip)
                    } else {
                        await self?.showChipsGroupPicker(with: chip.id)
                    }
                }
            )
        }
        
        updateChipsItems(with: updatedChips)
    }

    private func subchipsFrom(
        appliedChips: [SearchChipEntity],
        allChips: [SearchChipEntity]
    ) -> [ChipViewModel] {
        allChips.map { chip in
            let selected = appliedChips.contains(where: { $0.id == chip.id })
            return ChipViewModel(
                id: chip.title,
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

    private func selected(for chip: SearchChipEntity, appliedChips: [SearchChipEntity]) -> Bool {
        if chip.subchips.isNotEmpty {
            return chip.subchips.filter { subchip in
                appliedChips.contains(where: { $0.type.isInSameChipGroup(as: subchip.type) })
            }.isNotEmpty
        } else {
            return appliedChips.contains(chip)
        }
    }

    private func icon(for chip: SearchChipEntity, selected: Bool) -> PillView.Icon {
        if chip.subchips.isNotEmpty {
            return .trailing(Image(systemName: "chevron.down"))
        } else {
            return selected ? .leading(Image(systemName: "checkmark")) : .none
        }
    }

    func showChipsGroupPicker(with id: String) async {
        guard let index = chipsItems.firstIndex(where: { $0.id == id }) else { return }
        presentedChipsPickerViewModel = chipsItems[index]
    }

    func dismissChipGroupPicker() async {
        presentedChipsPickerViewModel = nil
    }

    private func updateLoadingPlaceholderVisibility(_ shown: Bool) {
        isLoadingPlaceholderShown = shown
    }

    private func clearSearchResults() {
        listItems = []
    }
    
    func searchResultUpdated(_ result: SearchResult) async {
        guard let index = listItems.firstIndex(where: { $0.result.id == result.id  }) else { return }
        await listItems[index].reload(with: result)
    }

    private func searchResultsUpdated(_ results: [SearchResult]) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTasksUnlessCancelled(for: results) { result in
                await self.searchResultUpdated(result)
            }
        }
    }

    private func updateChipsItems(with chipViewModels: [ChipViewModel]) {
        chipsItems = chipViewModels
    }

    private func updateSearchResultsLoaded(_ loaded: Bool) {
        $areNewSearchResultsLoaded.mutate { $0 = loaded }
    }

    private func updateListItem(with newItems: [SearchResultRowViewModel]) {
        listItems = newItems
        let newEmptyViewModel = Self.makeEmptyView(
            whenListItems: listItems.isEmpty,
            query: currentQuery,
            appliedChips: currentQuery.chips,
            config: config
        )

        // Disable animation for iOS 15 to avoid app crash
        // IOS-9571: iOS 15 crash adding files to an empty folder
        if #available(iOS 16.0, *) {
            withAnimation {
                emptyViewModel = newEmptyViewModel
            }
        } else {
            emptyViewModel = newEmptyViewModel
        }
    }

    private func refreshSearchResults() async throws {
        try Task.checkCancellation()
        guard let searchResults = try await resultsProvider.refreshedSearchResults(queryRequest: currentQuery) else {
            updateListItem(with: [])
            return
        }
        
        // to keep the same behaviour as in legacy cloud drive, when last item is removed
        // from recent action bucket, we should dismiss the screen
        // but the comment in there said we should show the empty screen if possible, so we will do that here in NCD
        
        try Task.checkCancellation()

        var newResultViewModels = [SearchResultRowViewModel]()
        for result in searchResults.results {
            let item = mapSearchResultToViewModel(result)
            // For items that already have their thumbnails fetched, we can reuse them
            if let existingItem = listItems.first(where: { $0.result.id == result.id }) {
                item.thumbnailImage = existingItem.thumbnailImage
                item.isThumbnailLoadedOnce = existingItem.isThumbnailLoadedOnce
            }
            newResultViewModels.append(item)
        }
        
        try Task.checkCancellation()
        updateListItem(with: newResultViewModels)
    }

    // when keyboard is shown we shouldn't add any additional bottom inset
    // when keyboard is hidden bottom inset should be equal to miniPlayerBottomInset
    // if mini player is displayed, miniPlayerBottomInset is equal miniplayer.height,
    // otherwise, it is equal to 0
    private func setupKeyboardVisibilityHandling() {
        keyboardVisibilityHandler.keyboardPublisher
            .sink(receiveValue: {[weak self] isShown in
                guard let self else { return }
                bottomInset = isShown ? 0 : miniPlayerBottomInset
            })
            .store(in: &subscriptions)
    }

    private func updatedQuery(with sortOrder: SortOrderEntity) -> SearchQuery {
        if currentQuery.sorting == sortOrder {
            return currentQuery
        } else {
            return .userSupplied(
                .init(
                    query: currentQuery.query,
                    sorting: sortOrder,
                    mode: currentQuery.mode,
                    isSearchActive: currentQuery.isSearchActive,
                    chips: currentQuery.chips
                )
            )
        }
    }

    private func observeListItemsUpdate() {
        $listItems
            .sink { [weak self] viewModels in
                guard let self else { return }
                
                selectedRowIds = viewModels.isEmpty
                ? []
                : Set(viewModels.compactMap { selectedResultIds.contains($0.result.id) ? $0.id : nil })
            }
            .store(in: &subscriptions)
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
    
    // create new query using new string while preserving other search params intact
    static private func makeQueryUsing(string: String, isSearchActive: Bool, current: SearchQuery) -> SearchQueryEntity {
        .init(
            query: string,
            sorting: current.sorting,
            mode: .home,
            isSearchActive: isSearchActive,
            chips: current.chips
        )
    }
}

fileprivate extension SearchConfig.EmptyViewAssets {
    var emptyViewModel: ContentUnavailableViewModel {
        .init(
            image: image,
            title: title,
            font: .body,
            titleTextColor: titleTextColor,
            actions: actions.map(\.action)
        )
    }
}

fileprivate extension SearchConfig.EmptyViewAssets.Action {
    var action: ContentUnavailableViewModel.MenuAction {
        .init(
            title: title,
            titleTextColor: titleTextColor,
            backgroundColor: backgroundColor,
            actions: menu.map(\.buttonAction)
        )
    }
}

fileprivate extension SearchConfig.EmptyViewAssets.MenuOption {
    var buttonAction: ContentUnavailableViewModel.ButtonAction {
        .init(title: title, image: image, handler: handler)
    }
}

public extension SearchResultsViewModel {
    var selectedResultsCount: Int {
        selectedResultIds.count
    }

    func toggleSelectAll() {
        let currentResultsIds = resultsProvider.currentResultIds()
        if Set(currentResultsIds) == selectedResultIds {
            selectedResultIds.removeAll()
            selectedRowIds.removeAll()
        } else {
            selectedResultIds = Set(currentResultsIds)
            selectedRowIds = Set(listItems.map { $0.id })
        }
    }

    @discardableResult
    func changeSortOrder(_ sortOrder: SortOrderEntity) -> Task<Void, Never> {
        Task { @MainActor in
            let query = updatedQuery(with: sortOrder)
            await showLoadingPlaceholderIfNeeded()
            await queryChanged(to: query)
        }
    }

    func clearSelection() {
        selectedResultIds.removeAll()
        selectedRowIds.removeAll()
    }
}
