import Foundation
import MEGADomain

/// In memory cache for search history items
public actor VisualMediaSearchHistoryCacheRepository: VisualMediaSearchHistoryRepositoryProtocol {
    public static let sharedRepo = VisualMediaSearchHistoryCacheRepository()
    
    private let notificationCenter: NotificationCenter
    private var recentSearches: [SearchTextHistoryEntryEntity] = []
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        
        Task {
            await observeAccountLogout()
        }
    }
    
    public func history() async -> [SearchTextHistoryEntryEntity] {
        recentSearches
    }
    
    public func add(entry: SearchTextHistoryEntryEntity) async {
        if let existingIndex = recentSearches.firstIndex(
            where: { $0.query.localizedCaseInsensitiveContains(entry.query) }) {
            recentSearches.remove(at: existingIndex)
        }
        recentSearches.append(entry)
    }
    
    public func delete(entry: SearchTextHistoryEntryEntity) async {
        recentSearches.remove(object: entry)
    }
    
    private func observeAccountLogout() async {
        for await _ in notificationCenter.notifications(named: .accountDidLogout).map({ _ in () }) {
            recentSearches.removeAll()
        }
    }
}
