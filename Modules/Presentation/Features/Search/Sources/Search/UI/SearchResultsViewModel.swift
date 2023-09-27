import Combine
import MEGASwift
import MEGASwiftUI
import SwiftUI

public class SearchResultsViewModel: ObservableObject {
    @Published var listItems: [SearchResultRowViewModel]  = []
    @Published var chipsItems: [ChipViewModel] = []
    @Published var bottomInset: CGFloat = 0.0
    @Published var emptyViewModel: ContentUnavailableView_iOS16ViewModel?
    @Published var isLoadingPlaceholderShown = false

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

    // this flag is used to indicate whether the data has been loaded for every triggered search
    @Atomic var areNewSearchResultsLoaded = false
    
    // data source for the results (result list, chips)
    private let resultsProvider: any SearchResultsProviding

    private let config: SearchConfig

    // delay after we should display loading placeholder, in seconds
    private let showLoadingPlaceholderDelay: Double

    private let keyboardVisibilityHandler: any KeyboardVisibiltyHandling

    public init(
        resultsProvider: any SearchResultsProviding,
        bridge: SearchBridge,
        config: SearchConfig,
        showLoadingPlaceholderDelay: Double = 1,
        keyboardVisibilityHandler: any KeyboardVisibiltyHandling
    ) {
        self.resultsProvider = resultsProvider
        self.bridge = bridge
        self.config = config
        self.showLoadingPlaceholderDelay = showLoadingPlaceholderDelay
        self.keyboardVisibilityHandler = keyboardVisibilityHandler

        self.bridge.queryChanged = { [weak self] query  in
            let _self = self
            Task {
                await _self?.showLoadingPlaceholderIfNeeded()
                await _self?.queryChanged(to: query)
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
        guard !initialLoadDone else { return }
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
    
    func queryCleaned() async {
        // clearing query in the search bar
        // this should reset just query string but keep chips etc
        await showLoadingPlaceholderIfNeeded()
        await queryChanged(to: "")
    }
    
    @MainActor
    func searchCancelled() async {
        // cancel button on the search bar was tapped
        // clear items, chips, initialLoadDone so that we load fresh
        // data when view appears again
        initialLoadDone = false
        currentQuery = .initial
        listItems = []
        chipsItems = []
        lastAvailableChips = []
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
            await updateLoadingPlaceholderVisibility(true)
        }
    }
    
    private func queryChanged(to query: SearchQuery) async {
        cancelSearchTask()
        // we need to store query to know what chips are selected
        currentQuery = query

        searchingTask = Task {
            await performSearch(using: query)
        }
        
        try? await searchingTask?.value
    }
    
    private func performSearch(using query: SearchQuery) async {
        updateSearchResultsLoaded(false)

        if Task.isCancelled { return }
        
        var results: SearchResultsEntity?
        do {
            results = try await resultsProvider.search(queryRequest: query)
        } catch {
            // error handling to be done
            // in the FM-800
        }
        
        guard let results else { return }
        
        if Task.isCancelled { return }

        await consume(results, query: query)
        updateSearchResultsLoaded(true)
        await updateLoadingPlaceholderVisibility(false)
    }
    
    @MainActor
    private func consume(_ results: SearchResultsEntity, query: SearchQuery) {
        lastAvailableChips = results.availableChips
        updateChipsFrom(appliedChips: results.appliedChips)
        
        listItems = results.results.map { result in
            SearchResultRowViewModel(
                with: result,
                contextButtonImage: config.rowAssets.contextImage,
                contextAction: { [weak self] button in
                    // we pass in button to show popover attached to the correct view
                    self?.bridge.context(result, button)
                },
                selectionAction: { [weak self] in
                    // executeSelect
                    self?.bridge.selection(result)
                }
            )
        }
        
        emptyViewModel = Self.makeEmptyView(
            whenListItems: listItems.isEmpty,
            appliedChips: results.appliedChips,
            config: config
        )
    }
    
    private static func makeEmptyView(
        whenListItems empty: Bool,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableView_iOS16ViewModel? {
        guard empty else { return nil }
        
        // this assumes only one chip at most can be applied at any given time
        let content = config.emptyViewAssetFactory(appliedChips.first)
        
        return .init(
            image: content.image,
            title: content.title,
            font: Font.callout.bold(),
            color: content.foregroundColor
        )
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
    
    private func updateChipsFrom(
        appliedChips: [SearchChipEntity]
    ) {
        chipsItems = lastAvailableChips.map { chip in
            ChipViewModel(
                chipId: chip.id,
                pill: .init(
                    title: chip.title,
                    selected: appliedChips.contains(chip),
                    config: config.chipAssets
                ),
                select: {[weak self] in
                    await self?.tapped(chip)
                }
            )
        }
    }
    
    @MainActor
    private func updateLoadingPlaceholderVisibility(_ shown: Bool) {
        isLoadingPlaceholderShown = shown
    }

    private func updateSearchResultsLoaded(_ loaded: Bool) {
        $areNewSearchResultsLoaded.mutate { currentValue in
            currentValue = loaded
        }
    }

    // when keyboard is shown we shouldn't add any additional bottom inset
    // when keyboard is hidden bottom inset should be equal to miniPlayerBottomInset
    // if mini player is displayed, miniPlayerBottomInset is equal miniplayer.height,
    // otherwise, it is equal to 0
    private func setupKeyboardVisibilityHandling() {
        keyboardVisibilityHandler.keyboardPublisher
            .sink(receiveValue: { isShown in
                self.bottomInset = isShown ? 0 : self.miniPlayerBottomInset
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
            if chips.contains(chip) {
                chips.remove(object: chip)
            } else {
                chips.removeAll()
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
