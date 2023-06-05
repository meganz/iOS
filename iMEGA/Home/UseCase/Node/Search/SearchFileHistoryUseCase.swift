import Foundation

protocol SearchFileHistoryUseCaseProtocol {

    func searchHistoryEntries() -> [SearchFileHistoryEntryDomain]

    func saveSearchHistoryEntry(_ entry: SearchFileHistoryEntryDomain)

    func clearSearchHistoryEntries()
}

final class SearchFileHistoryUseCase: SearchFileHistoryUseCaseProtocol {
    
    private enum Constant {
        static let oneDay: TimeInterval = 60 * 60 * 24
        static let twoDays: TimeInterval = oneDay * 2
        static let maximumNumberOfHistoryEntries = 50
    }

    private var searchHintsUpdatingStrategies: [SearchEntryUpdating] = [
        .excludingEmpty,
        .replaceExistingWithinDuration(Constant.oneDay),
        .appendingNewEntry,
        .sortedBySearchTime,
        .excludingEntriesOver(Constant.maximumNumberOfHistoryEntries)
    ]

    private lazy var searchHistoryCache: [SearchFileHistoryEntryDomain] = []
    
    private var fileSearchHistoryRepository: FileSearchHistoryRepository

    init(
        fileSearchHistoryRepository: FileSearchHistoryRepository
    ) {
        self.fileSearchHistoryRepository = fileSearchHistoryRepository
        self.searchHistoryCache = (try? fileSearchHistoryRepository.loadSearchHistory()) ?? []
    }

    func searchHistoryEntries() -> [SearchFileHistoryEntryDomain] {
        searchHistoryCache
    }

    func saveSearchHistoryEntry(_ newEntry: SearchFileHistoryEntryDomain) {
        let updatedSearchHistoryEntries = searchHintsUpdatingStrategies.reduce((searchHistoryEntries(), newEntry)) { result, strategy in
            strategy.updatingSearchHistoryEntries(result.0, result.1)
        }.0
        try? fileSearchHistoryRepository.saveSearchHistory(updatedSearchHistoryEntries)
        self.searchHistoryCache = updatedSearchHistoryEntries
    }

    func clearSearchHistoryEntries() {
        try? fileSearchHistoryRepository.clearHistory()
    }
}

// MARK: - SearchEntryUpdating

private struct SearchEntryUpdating {
    
    var updatingSearchHistoryEntries: (
        _ searchHistoryEntries: [SearchFileHistoryEntryDomain],
        _ searchEntry: SearchFileHistoryEntryDomain?
    ) -> ([SearchFileHistoryEntryDomain], SearchFileHistoryEntryDomain?)
}

extension SearchEntryUpdating {
    
    static var identity: Self {
        Self { histories, newEntry in
            (histories, newEntry)
        }
    }
    
    static var appendingNewEntry: Self {
        Self { histories, newEntry in
            guard let newEntry = newEntry else {
                return (histories, nil)
            }
            return (histories + [newEntry], nil)
        }
    }

    static var sortedBySearchTime: Self {
        Self { histories, newEntry in
            return (histories.sorted(), newEntry)
        }
    }

    static var excludingEmpty: Self {
        Self { histories, newEntry in
            guard let newEntry = newEntry else {
                return (histories, nil)
            }

            if newEntry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return (histories, nil)
            }
            return (histories, newEntry)
        }
    }

    static var excludingOlderThan: (TimeInterval) -> Self {
        { distanceInSeconds in
            Self { histories, newEntry in
                guard let newEntry = newEntry else {
                    return (histories, nil)
                }

                let excludingOutdatedEntries = histories.filter {
                    abs($0.timeWhenSearchOccur.timeIntervalSinceNow) < distanceInSeconds
                }
                return (excludingOutdatedEntries, newEntry)
            }
        }
    }

    static var excludingEntriesOver: (Int) -> Self {
        { totalAmount in
            Self { histories, _ in
                let excludingOutdatedEntries = Array(histories.prefix(totalAmount))
                return (excludingOutdatedEntries, nil)
            }
        }
    }

    static var replaceExistingWithinDuration: (TimeInterval) -> Self {
        { duration in
            Self { histories, newEntry in
                guard let newEntry = newEntry else {
                    return (histories, nil)
                }

                let excludedOlderEntriesHistory: [SearchFileHistoryEntryDomain] = histories.compactMap {
                    if $0.text == newEntry.text &&
                        newEntry.timeWhenSearchOccur.timeIntervalSince($0.timeWhenSearchOccur) <= duration {
                        return nil
                    }
                    return $0
                }
                return (excludedOlderEntriesHistory, newEntry)
            }
        }
    }
}

@objc(SearchFileUseCase)
final class SearchFileHistoryUseCaseOCCompatible: NSObject {

    private let searchFileUseCase: SearchFileHistoryUseCaseProtocol = SearchFileHistoryUseCase(
        fileSearchHistoryRepository: .live
    )

    @objc
    func clearFileSearchHistoryEntries() {
        searchFileUseCase.clearSearchHistoryEntries()
    }
}
