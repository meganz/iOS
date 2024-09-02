public protocol VisualMediaSearchHistoryUseCaseProtocol: Sendable {
    /// Retrieves the search history, if it exists.
    /// - Returns: Search history entries if any sorted from most recent to oldest
    func history() async -> [SearchTextHistoryEntryEntity]
    /// Add search history entry to history
    /// - Parameters: entry - the search history entry to add
    func add(entry: SearchTextHistoryEntryEntity) async
}

public struct VisualMediaSearchHistoryUseCase<T: VisualMediaSearchHistoryRepositoryProtocol>: VisualMediaSearchHistoryUseCaseProtocol {
    private let visualMediaSearchHistoryRepository: T
    
    private let maxSearchSearchHistoryCount = 6
    
    public init(visualMediaSearchHistoryRepository: T) {
        self.visualMediaSearchHistoryRepository = visualMediaSearchHistoryRepository
    }
    
    public func history() async -> [SearchTextHistoryEntryEntity] {
        await visualMediaSearchHistoryRepository.history()
            .sorted { $0.searchDate > $1.searchDate }
    }
    
    public func add(entry: SearchTextHistoryEntryEntity) async {
        await visualMediaSearchHistoryRepository.add(entry: entry)
        
        let searchQueryHistory = await history()
        guard searchQueryHistory.count > maxSearchSearchHistoryCount else { return }
        
        guard let lastHistoryItem = searchQueryHistory.last else { return }
        await visualMediaSearchHistoryRepository.delete(entry: lastHistoryItem)
    }
}
