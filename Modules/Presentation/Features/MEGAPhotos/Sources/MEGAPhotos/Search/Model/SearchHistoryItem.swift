import Foundation

struct SearchHistoryItem: Identifiable, Equatable {
    let id: UUID
    let query: String
    
    init(id: UUID, query: String) {
        self.id = id
        self.query = query
    }
}
