import Combine
import Foundation
import MEGADomain

@MainActor
public class VisualMediaSearchResultsViewModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case empty
        case recentlySearched(items: [SearchHistoryItem])
        case searchResults
    }
    @Published private(set) var viewState: ViewState = .loading
    @Published var searchText = ""
    
    private let visualMediaSearchHistoryUseCase: any VisualMediaSearchHistoryUseCaseProtocol
    private let searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride
    private let debounceQueue: DispatchQueue
    
    private let searchHistoryDataProvider = SearchHistoryDataProvider()
    
    private var searchTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    
    public init(visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol,
                searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
                debounceQueue: DispatchQueue = DispatchQueue(label: "nz.mega.VisualMediaSearchDebounceQueue", qos: .userInitiated)) {
        self.visualMediaSearchHistoryUseCase = visualMediaSearchHistoryUseCase
        self.searchDebounceTime = searchDebounceTime
        self.debounceQueue = debounceQueue
    }
    
    func monitorSearchResults() async {
        let searchText = $searchText
            .debounceImmediate(for: searchDebounceTime, scheduler: debounceQueue)
            .removeDuplicates()
        
        for await searchQuery in searchText.values {
            performSearch(searchText: searchQuery)
        }
    }
    
    func onViewDisappear() async {
        guard await !searchHistoryDataProvider.isEmpty else { return }
        
        try? await visualMediaSearchHistoryUseCase.save(entries: searchHistoryDataProvider.recentSearches)
    }
    
    private func performSearch(searchText: String) {
        searchTask = Task {
            guard searchText.isNotEmpty else {
                await loadRecentlySearchedItems()
                return
            }
            
            if shouldShowLoading() {
                viewState = .loading
            }
            
            try Task.checkCancellation()
            
            // Perform search here and populate result in enum
            
            await searchHistoryDataProvider.addRecentSearch(searchText)
            
            try Task.checkCancellation()
            viewState = .searchResults
        }
    }
    
    private func loadRecentlySearchedItems() async {
        guard await searchHistoryDataProvider.isEmpty else {
            viewState = await .recentlySearched(items: searchHistoryDataProvider.historyItems())
            return
        }
        
        guard let historyEntries = try? await visualMediaSearchHistoryUseCase.searchQueryHistory(),
              historyEntries.isNotEmpty else {
            viewState = .empty
            return
        }
        await searchHistoryDataProvider.addRecentSearches(historyEntries)
        
        guard !Task.isCancelled else { return }
        viewState = await .recentlySearched(items: searchHistoryDataProvider.historyItems())
    }
    
    private func shouldShowLoading() -> Bool {
        guard viewState != .loading else { return false }
        
        return switch viewState {
        case .empty, .recentlySearched: true
        default: false
        }
    }
}

private actor SearchHistoryDataProvider {
    private let maxSearchSearchHistoryCount = 6
    
    var recentSearches: [SearchTextHistoryEntryEntity] = []
    
    var isEmpty: Bool {
        recentSearches.isEmpty
    }
    
    func addRecentSearches(_ searches: [SearchTextHistoryEntryEntity]) {
        recentSearches.append(contentsOf: searches)
        recentSearches.sort { $0.searchDate > $1.searchDate }
        recentSearches = Array(recentSearches.prefix(maxSearchSearchHistoryCount))
    }
    
    func addRecentSearch(_ searchText: String) {
        recentSearches.insert(.init(id: UUID(), query: searchText, searchDate: Date()), at: 0)
        guard recentSearches.count > maxSearchSearchHistoryCount else { return }
        recentSearches.removeLast()
    }
    
    func historyItems() -> [SearchHistoryItem] {
        recentSearches.toSearchHistoryItems()
    }
}
