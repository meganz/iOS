import MEGASwift
import MEGASwiftUI
import SwiftUI

public class SearchResultsViewModel: ObservableObject {
    @Published var listItems: [SearchResultRowViewModel]  = []
    @Published var chipsItems: [ChipViewModel] = []
    @Published var bottomInset: CGFloat = 0.0
    
    // this is needed to be able to construct new query after receiving new query string from SearchBar
    private var currentQuery: SearchQuery = .initial
    
    // keep information what were the available chips received with latest
    // results so that we know how to modify the list of chips after
    // selection was changed but we don't have new results
    private var lastAvailableChips: [SearchChipEntity] = []
    
    // do not load when coming back from the pushed vc
    private var initialLoadDone = false
    
    // communication back and forth to the parent and searchbar
    public let bridge: SearchBridge
    
    // current task that needs to be cancelled when we modify
    // query string or selected chips while previous search is being
    // executed
    private var searchingTask: Task<Void, any Error>?
    
    // data source for the results (result list, chips)
    private let resultsProvider: any SearchResultsProviding
    
    private let config: SearchConfig
    
    public init(
        resultsProvider: any SearchResultsProviding,
        bridge: SearchBridge,
        config: SearchConfig
    ) {
        self.resultsProvider = resultsProvider
        self.bridge = bridge
        self.config = config
        
        self.bridge.queryChanged = { [weak self] query  in
            let _self = self
            Task { await _self?.queryChanged(to: query) }
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
            self?.bottomInset = inset
        }
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
        await queryChanged(to: .initial)
    }
    
    private func cancelSearchTask() {
        searchingTask?.cancel()
        searchingTask = nil
    }
    
    func queryCleaned() async {
        // clearing query in the search bar
        // this should reset just query string but keep chips etc
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
    }
    
    @MainActor
    private func consume(_ results: SearchResultsEntity, query: SearchQuery) {
        lastAvailableChips = results.availableChips
        updateChipsFrom(appliedChips: results.appliedChips)
        
        listItems = results.results.map { result in
            SearchResultRowViewModel(
                with: result,
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
    }
    
    @MainActor
    private func tapped(_ chip: SearchChipEntity) async {
        let query = Self.makeQueryAfter(tappedChip: chip, currentQuery: currentQuery)
        // updating chips here as well to make selection visible before results are returned
        updateChipsFrom(appliedChips: query.chips)
        await queryChanged(to: query)
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
