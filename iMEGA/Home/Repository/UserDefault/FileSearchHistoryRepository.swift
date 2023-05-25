import Foundation

struct FileSearchHistoryRepository {

    let saveSearchHistory: (
        _ searchHistory: [SearchFileHistoryEntryDomain]
    ) throws -> Void

    let loadSearchHistory: () throws -> [SearchFileHistoryEntryDomain]

    let clearHistory: () throws -> Void
}

extension FileSearchHistoryRepository {

    enum PersistanceKey: String {
        case fileSearchHistoryEntries
    }

    static var live: Self {
        let userDefaults = UserDefaults.standard

        return Self.init(saveSearchHistory: { searchHistory in
            let fileSearchHistoryEntryEncodable = searchHistory.map(FileSearchHistoryEntity.init(with:))
            let encodedSearchHistory = try JSONEncoder().encode(fileSearchHistoryEntryEncodable)
            userDefaults.set(
                encodedSearchHistory,
                forKey: PersistanceKey.fileSearchHistoryEntries.rawValue
            )
        },

        loadSearchHistory: {
            guard let searchHistory =
                userDefaults.value(forKey: PersistanceKey.fileSearchHistoryEntries.rawValue) as? Data else {
                return []
            }
            let decodedSearchHistory = try JSONDecoder()
                .decode([FileSearchHistoryEntity].self, from: searchHistory)
            return decodedSearchHistory.map {
                SearchFileHistoryEntryDomain(
                    text: $0.searchText,
                    timeWhenSearchOccur: $0.searchTime
                )
            }
        },

        clearHistory: {
            let encodedSearchHistory = try JSONEncoder().encode([].map(FileSearchHistoryEntity.init(with:)))
            userDefaults.set(
                encodedSearchHistory,
                forKey: PersistanceKey.fileSearchHistoryEntries.rawValue
            )
        })
    }
}

private struct FileSearchHistoryEntity: Codable {
    let searchText: String
    let searchTime: Date
}

extension FileSearchHistoryEntity {
    init(with fileSearchHistory: SearchFileHistoryEntryDomain) {
        self.searchText = fileSearchHistory.text
        self.searchTime = fileSearchHistory.timeWhenSearchOccur
    }
}
