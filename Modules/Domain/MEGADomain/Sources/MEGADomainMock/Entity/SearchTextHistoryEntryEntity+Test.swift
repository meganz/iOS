import Foundation
import MEGADomain

public extension SearchTextHistoryEntryEntity {
    init(id: UUID = UUID(),
         query: String = "",
         searchDate: Date = Date(),
         isTesting: Bool = true) {
        self.init(
            id: id,
            query: query,
            searchDate: searchDate
        )
    }
}
