import SwiftUI

public class SearchResultsViewModel: ObservableObject {
    @Published var listItems: [SearchResultRowViewModel]  = []

    let bridge: SearchBridge

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
    }
    
    func queryCleaned() {
        listItems = []
        // show empty view here
    }
    
    func searchCancelled() {
        // cancel button on the searrch bar was tapped
        listItems = []
    }
    
    func queryChanged(to query: String) {
        
        let queryEntity = SearchQueryEntity(
            query: query,
            sorting: .automatic,
            mode: .home,
            chips: []
        )
        
        Task { @MainActor in
            await performSearch(using: queryEntity)
        }
    }
    
    @MainActor
    func performSearch(using query: SearchQueryEntity) async {
        if query.query.isEmpty {
            queryCleaned()
            return
        }
        
        var result: SearchResultsEntity?
        do {
            result = try await resultsProvider.search(queryRequest: query)
        } catch {
            // present error
        }
        
        guard let result else { return }
        
        listItems = result.results.map { result in
            SearchResultRowViewModel(
                with: result,
                contextAction: { [weak self] in
                    // present menucontext
                    self?.bridge.context(result)
                },
                selectionAction: { [weak self] in
                    // executeSelect
                    self?.bridge.selection(result)
                }
            )
        }
    }
}
