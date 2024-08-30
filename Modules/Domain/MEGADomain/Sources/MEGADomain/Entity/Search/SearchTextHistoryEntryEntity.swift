import Foundation

public struct SearchTextHistoryEntryEntity: Sendable, Identifiable {
    public let id: UUID
    public let query: String
    public let searchDate: Date
    
    public init(
        id: UUID,
        query: String,
        searchDate: Date
    ) {
        self.id = id
        self.query = query
        self.searchDate = searchDate
    }
}

extension SearchTextHistoryEntryEntity: Hashable {
    public static func == (lhs: SearchTextHistoryEntryEntity, rhs: SearchTextHistoryEntryEntity) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
