import Combine
import MEGASwift
import MEGASwiftUI
import SwiftUI

public class SearchResultsViewModel: ObservableObject {
    @Published var listItems: [SearchResultRowViewModel]  = []
    @Published var bottomInset: CGFloat = 0.0
    @Published var emptyViewModel: ContentUnavailableView_iOS16ViewModel?
    @Published var isLoadingPlaceholderShown = false

    // this will need to be to exposed outside when parent will need to know exactly what is selected
    @Published var selected: Set<ResultId> = []

    @Published public var layout: PageLayout

    @Published var chipsItems: [ChipViewModel] = []
    @Published var presentedChipsPickerViewModel: ChipViewModel?

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

    // this is needed to be able to construct new query after receiving new query string from SearchBar
    private var currentQuery: SearchQuery = .initial

    // keep information what were the available chips received with latest
    // results so that we know how to modify the list of chips after
    // selection was changed but we don't have new results
    private var lastAvailableChips: [SearchChipEntity] = []

    // do not load when coming back from the pushed vc
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
    @Atomic var areNewSearchResultsLoaded = false

    // data source for the results (result list, chips)
    private let resultsProvider: any SearchResultsProviding

    private let config: SearchConfig

    // delay after we should display loading placeholder, in seconds
    private let showLoadingPlaceholderDelay: Double

    // delay after which we trigger searching after the user stops typing, in seconds
    private let searchInputDebounceDelay: Double

    private let keyboardVisibilityHandler: any KeyboardVisibilityHandling

    @Published public var editing: Bool = false
    
    public init(
        resultsProvider: any SearchResultsProviding,
        bridge: SearchBridge,
        config: SearchConfig,
        layout: PageLayout,
        showLoadingPlaceholderDelay: Double = 1,
        searchInputDebounceDelay: Double = 0.5,
        keyboardVisibilityHandler: any KeyboardVisibilityHandling
    ) {
        self.resultsProvider = resultsProvider
        self.bridge = bridge
        self.config = config
        self.showLoadingPlaceholderDelay = showLoadingPlaceholderDelay
        self.searchInputDebounceDelay = searchInputDebounceDelay
        self.keyboardVisibilityHandler = keyboardVisibilityHandler
        self.layout = layout
        self.bridge.queryChanged = { [weak self] query  in
            let _self = self
            
            _self?.debounceTask?.cancel()
            _self?.debounceTask = Task {
                try await Task.sleep(nanoseconds: UInt64(searchInputDebounceDelay*1_000_000_000))
                await _self?.showLoadingPlaceholderIfNeeded()
                await _self?.queryChanged(to: query)
            }
        }

        self.bridge.searchResultChanged = { [weak self] result in
            let _self = self
            Task { await _self?.searchResultUpdated(result) }
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

        setupKeyboardVisibilityHandling()
    }

    /// meant called to be called in the SwiftUI View's .task modifier
    /// which means task is called on the appearance and cancelled on disappearance
    @MainActor
    func task() async {
        // We need to check if listItems is empty  because after first load of the screen, the listItems will be filled with data,
        // so there is no need for additional query which will only cause flicker when we quickly go in and out of this screen
        guard !initialLoadDone, listItems.isEmpty else { return }
        initialLoadDone = true
        await defaultSearchQuery()
    }
    
    private func defaultSearchQuery() async {
        // when screen is presented first time,
        // do an initial search that lists contents of the directory
        // This is using a different method in the SDK
        // hence an enum is needed to reliably tell the difference
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: .initial)
    }
    
    private func cancelSearchTask() {
        searchingTask?.cancel()
        searchingTask = nil
    }

    private func cancelDebounceTask() {
        debounceTask?.cancel()
        debounceTask = nil
    }

    @MainActor
    func queryCleaned() async {
        // clearing query in the search bar
        // this should reset just query string but keep chips etc
        cancelDebounceTask()
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: "")
    }
    
    func scrolled() {
        if searchingTask == nil {
            bridge.resignKeyboard()
        }
    }

    @MainActor
    func searchCancelled() async {
        // cancel button on the search bar was tapped
        // clear items, chips, initialLoadDone so that we load fresh
        // data when view appears again
        initialLoadDone = false
        editing = false
        currentQuery = .initial
        listItems = []
        lastAvailableChips = []
        selected = []
        await defaultSearchQuery()
    }
    
    func queryChanged(to query: String) async {
        await queryChanged(to: .userSupplied(Self.makeQueryUsing(string: query, current: currentQuery)))
    }

    // After the user triggered new search query, if the results don't come in more than 1 second
    // we should display the shimmer placeholder while the search results loading finishes
    // If the search results are already loaded -> areNewSearchResultsLoaded = true, we shouldn't display shimmer loading
    func showLoadingPlaceholderIfNeeded() async {
        Task {
            try await Task.sleep(nanoseconds: UInt64(showLoadingPlaceholderDelay*1_000_000_000))
            guard !areNewSearchResultsLoaded else { return }
            updateLoadingPlaceholderVisibility(true)
        }
    }

    @MainActor
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
        searchingTask = nil
    }
    
    @MainActor
    private func performSearch(
        using query: SearchQuery,
        lastItemIndex: Int? = nil
    ) async {
        if lastItemIndex == nil {
            updateSearchResultsLoaded(false)
        }

        if Task.isCancelled { return }
        
        var results: SearchResultsEntity?
        do {
            results = try await resultsProvider.search(queryRequest: query, lastItemIndex: lastItemIndex)
        } catch {
            // error handling to be done
            // in the FM-800
        }

        if Task.isCancelled { return }
        
        guard let results else { return }

        if lastItemIndex == nil {
            clearSearchResults()
        }

        await prepareResults(results, query: query)
    }

    func loadMoreIfNeeded(at index: Int) async {
        await performSearch(using: currentQuery, lastItemIndex: index)
    }

    func loadMoreIfNeededThumbnailMode(at index: Int, isFile: Bool) async {
        var index = index
        if isFile {
            index += folderListItems.count
        } else if fileListItems.isNotEmpty {
            index += fileListItems.count
        }
        await loadMoreIfNeeded(at: index)
    }

    @MainActor
    func prepareResults(_ results: SearchResultsEntity, query: SearchQuery) async {

        let items = results.results.map { result in
            mapSearchResultToViewModel(result)
        }

        consume(results, items: items, query: query)
    }

    private func mapSearchResultToViewModel(_ result: SearchResult) -> SearchResultRowViewModel {
        let content = config.contextPreviewFactory.previewContentForResult(result)
        return SearchResultRowViewModel(
            result: result,
            rowAssets: config.rowAssets,
            colorAssets: config.colorAssets,
            previewContent: .init(
                actions: content.actions.map({ action in
                    return .init(
                        title: action.title,
                        imageName: action.imageName,
                        handler: { [weak self] in
                            self?.actionPressedOn(result)
                            action.handler()
                        }
                    )
                }),
                previewMode: content.previewMode
            ),
            actions: rowActions(for: result)
        )
    }

    func actionPressedOn(_ result: SearchResult) {
        if !editing {
            editing = true
        }
        toggleSelected(result)
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

    private func toggleSelected(_ result: SearchResult) {
        
        if selected.contains(result.id) {
            selected.remove(result.id)
        } else {
            selected.insert(result.id)
        }
        
    }
    
    private func rowActions(for result: SearchResult) -> SearchResultRowViewModel.UserActions {
        .init(
            contextAction: { [weak self] button in
                // we pass in button to show popover attached to the correct view
                self?.bridge.context(result, button)
            },
            selectionAction: { [weak self] in
                guard let self else { return }
                if editing {
                    toggleSelected(result)
                } else {
                    bridge.selection(result)
                }
            },
            previewTapAction: { [weak self] in
                self?.bridge.selection(result)
            }
        )
    }

    func consume(
        _ results: SearchResultsEntity,
        items: [SearchResultRowViewModel],
        query: SearchQuery
    ) {
        updateSearchResultsLoaded(true)
        updateLoadingPlaceholderVisibility(false)

        lastAvailableChips = results.availableChips
        updateChipsFrom(appliedChips: results.appliedChips)

        self.listItems.append(contentsOf: items)

        emptyViewModel = Self.makeEmptyView(
            whenListItems: listItems.isEmpty,
            textQuery: query.query,
            appliedChips: results.appliedChips,
            config: config
        )
    }
    
    private static func makeEmptyView(
        whenListItems empty: Bool,
        textQuery: String,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableView_iOS16ViewModel? {
        guard empty else { return nil }
        
        // we show contextual, chip-related empty screen only when there
        // is not text query
        if textQuery.isEmpty {
            // this assumes only one chip at most can be applied at any given time
            return config.emptyViewAssetFactory(appliedChips.first).emptyViewModel
        }
        
        // when there is non-empty text query (and no results of course) ,
        // [independently if there is any chip selected
        // we show generic 'no results' empty screen
        return config.emptyViewAssetFactory(nil).emptyViewModel
    }
    
    @MainActor
    private func tapped(_ chip: SearchChipEntity) async {
        let query = Self.makeQueryAfter(tappedChip: chip, currentQuery: currentQuery)
        // updating chips here as well to make selection visible before results are returned
        updateChipsFrom(appliedChips: query.chips)
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: query)
        bridge.chip(tapped: chip, isSelected: query.chips.contains(chip))
    }

    private func updateChipsFrom(appliedChips: [SearchChipEntity]) {
        chipsItems = lastAvailableChips.map { chip in
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

    @MainActor
    func showChipsGroupPicker(with id: String) async {
        guard let index = chipsItems.firstIndex(where: { $0.id == id }) else { return }
        presentedChipsPickerViewModel = chipsItems[index]
    }

    @MainActor
    func dismissChipGroupPicker() async {
        presentedChipsPickerViewModel = nil
    }

    private func updateLoadingPlaceholderVisibility(_ shown: Bool) {
        Task { @MainActor in
            isLoadingPlaceholderShown = shown
        }
    }

    private func clearSearchResults() {
        listItems = []
    }

    private func updateSearchResultsLoaded(_ loaded: Bool) {
        $areNewSearchResultsLoaded.mutate { currentValue in
            currentValue = loaded
        }
    }

    @MainActor
    func searchResultUpdated(_ result: SearchResult) async {
        guard let index = listItems.firstIndex(where: { $0.result.id == result.id  }) else { return }
        await listItems[index].reload(with: result)
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
                chips: modifyChips(tappedChip)
            )
        )
    }
    
    // create new query using new string while preserving other search params intact
    static private func makeQueryUsing(string: String, current: SearchQuery) -> SearchQueryEntity {
        .init(
            query: string,
            sorting: .automatic,
            mode: .home,
            chips: current.chips
        )
    }
}

fileprivate extension SearchConfig.EmptyViewAssets {
    var emptyViewModel: ContentUnavailableView_iOS16ViewModel {
        .init(
            image: image,
            title: title,
            font: Font.callout.bold(),
            color: foregroundColor
        )
    }
}
