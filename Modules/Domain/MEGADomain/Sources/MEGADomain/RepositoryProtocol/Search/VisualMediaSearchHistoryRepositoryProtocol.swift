public protocol VisualMediaSearchHistoryRepositoryProtocol: Sendable, SharedRepositoryProtocol {
    /// Retrieves the search history, if it exists.
    /// - Returns: Search history entries if any
    func history() async -> [SearchTextHistoryEntryEntity]
    /// Add search history entry to history
    /// - Parameters: entry - the search history entry to add
    func add(entry: SearchTextHistoryEntryEntity) async
    /// Delete search history from history
    /// - Parameters: entry - the search history entry to delete
    func delete(entry: SearchTextHistoryEntryEntity) async
}
