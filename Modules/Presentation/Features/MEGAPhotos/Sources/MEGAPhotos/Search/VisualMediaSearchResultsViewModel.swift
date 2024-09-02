import Combine
import Foundation
import MEGADomain

@MainActor
class VisualMediaSearchResultsViewModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case empty
        case recentlySearched(items: [SearchHistoryItem])
        case searchResults
    }
    @Published private(set) var viewState: ViewState = .loading
    @Published var searchText = ""
    @Published var selectedRecentlySearched: String?
    
    private let visualMediaSearchHistoryUseCase: any VisualMediaSearchHistoryUseCaseProtocol
    private let searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride
    private let debounceQueue: DispatchQueue
    
    private var searchTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    
    init(searchBarTextFieldUpdater: SearchBarTextFieldUpdater,
         visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol,
         searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
         debounceQueue: DispatchQueue = DispatchQueue(label: "nz.mega.VisualMediaSearchDebounceQueue", qos: .userInitiated)) {
        self.visualMediaSearchHistoryUseCase = visualMediaSearchHistoryUseCase
        self.searchDebounceTime = searchDebounceTime
        self.debounceQueue = debounceQueue
        
        $selectedRecentlySearched
            .assign(to: &searchBarTextFieldUpdater.$searchBarText)
    }
    
    func monitorSearchResults() async {
        let searchText = $searchText
            .debounceImmediate(for: searchDebounceTime, scheduler: debounceQueue)
            .removeDuplicates()
        
        for await searchQuery in searchText.values {
            performSearch(searchText: searchQuery)
        }
    }
    
    func saveSearch() async {
        guard searchText.isNotEmpty else { return }
        
        await visualMediaSearchHistoryUseCase.add(entry: .init(id: UUID(), query: searchText, searchDate: Date()))
    }
    
    private func performSearch(searchText: String) {
        searchTask = Task {
            guard searchText.isNotEmpty else {
                try await loadRecentlySearchedItems()
                return
            }
            
            if shouldShowLoading() {
                viewState = .loading
            }
            
            try Task.checkCancellation()
            
            // Perform search here and populate result in enum
            
            viewState = .searchResults
        }
    }
    
    private func loadRecentlySearchedItems() async throws {
        let searchHistoryItems = await visualMediaSearchHistoryUseCase.history()
        
        try Task.checkCancellation()
        
        viewState = if searchHistoryItems.isNotEmpty {
            .recentlySearched(items: searchHistoryItems.toSearchHistoryItems())
        } else {
            .empty
        }
    }
    
    private func shouldShowLoading() -> Bool {
        guard viewState != .loading else { return false }
        
        return switch viewState {
        case .empty, .recentlySearched: true
        default: false
        }
    }
}
