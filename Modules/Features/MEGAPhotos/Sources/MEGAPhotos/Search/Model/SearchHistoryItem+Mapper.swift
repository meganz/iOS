import MEGADomain

extension SearchTextHistoryEntryEntity {
    func toSearchHistoryItem() -> SearchHistoryItem {
        SearchHistoryItem(id: id, query: query)
    }
}

extension Sequence where Element == SearchTextHistoryEntryEntity {
    func toSearchHistoryItems() -> [SearchHistoryItem] {
        map { $0.toSearchHistoryItem() }
    }
}
