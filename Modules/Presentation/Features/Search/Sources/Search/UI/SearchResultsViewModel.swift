import SwiftUI

public class SearchResultsViewModel: ObservableObject {
    @Published var listItems: [SearchResultRowViewModel]  = []
    @Published var bottomInset: CGFloat = 0.0

    public let bridge: SearchBridge
    private var searchingTask: Task<Void, Error>?

    private let resultsProvider: any SearchResultsProviding
    
    public init(
        resultsProvider: any SearchResultsProviding,
        bridge: SearchBridge
    ) {
        self.resultsProvider = resultsProvider
        self.bridge = bridge
        
        self.bridge.queryChanged = { [weak self] in
            self?.queryChanged(to: $0)
        }
        
        self.bridge.queryCleaned = { [weak self] in
            self?.queryCleaned()
        }
        
        self.bridge.searchCancelled = { [weak self] in
            self?.searchCancelled()
        }
        
        self.bridge.updateBottomInset = { [weak self] inset in
            self?.bottomInset = inset
        }
    }
    
    func task() {
        // not loading anything by default at this stage
        // in next MR this will load contents of the current directory
    }
    
    private func defaultSearchResults() {
        // line below satisfy existing requirements to show non results
        // on launch and when query is empty
        listItems = []
        // to satisfy Scenario 1 in the FM-905, uncomment line below to show contents of the
        // root folder when query is empty
        // queryChanged(to: "")
    }
    
    private func cancelSearchTask() {
        searchingTask?.cancel()
        searchingTask = nil
    }
    
    func queryCleaned() {
        cancelCurrentSearchAndClearResults()
    }
    
    private func cancelCurrentSearchAndClearResults() {
        defaultSearchResults()
        cancelSearchTask()
    }
    
    func searchCancelled() {
        // cancel button on the search bar was tapped
        cancelCurrentSearchAndClearResults()
    }
    
    private func makeQueryUsing(string: String) -> SearchQueryEntity {
        .init(
            query: string,
            sorting: .automatic,
            mode: .home,
            chips: []
        )
    }
    
    func queryChanged(to query: String) {
        // this needs to be removed when
        // Scenario 1 in the FM-905 is implemented
        cancelSearchTask()
        
        guard !query.isEmpty else {
            defaultSearchResults()
            return
        }
        
        searchingTask = Task {
            await performSearch(using: makeQueryUsing(string: query))
        }
    }
    
    @MainActor
    func performSearch(using query: SearchQueryEntity) async {
        
        if Task.isCancelled { return }
        
        var result: SearchResultsEntity?
        do {
            result = try await resultsProvider.search(queryRequest: query)
        } catch {
            // error handling to be done
            // in the FM-800
        }
        
        guard let result else { return }
        
        if Task.isCancelled { return }
        
        listItems = result.results.map { result in
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
}
