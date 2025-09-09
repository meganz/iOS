import Foundation
import MEGADomain

/// In memory cache for search history items
public actor VisualMediaSearchHistoryCacheRepository: VisualMediaSearchHistoryRepositoryProtocol {
    public static let sharedRepo = VisualMediaSearchHistoryCacheRepository()
    
    private let notificationCenter: NotificationCenter
    private var recentSearches: [SearchTextHistoryEntryEntity] = []
    private var observeLogoutTask: Task<Void, Never>?
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }
    
    public func history() async -> [SearchTextHistoryEntryEntity] {
        recentSearches
    }
    
    public func add(entry: SearchTextHistoryEntryEntity) async {
        startObservingIfNeeded()
        if let existingIndex = recentSearches.firstIndex(
            where: { $0.query.localizedCaseInsensitiveContains(entry.query) }) {
            recentSearches.remove(at: existingIndex)
        }
        recentSearches.append(entry)
    }
    
    public func delete(entry: SearchTextHistoryEntryEntity) async {
        recentSearches.remove(object: entry)
    }
    
    private func startObservingIfNeeded() {
        guard observeLogoutTask == nil else { return }
        observeLogoutTask = Task { [weak self] in
            await self?.observeAccountLogout()
        }
    }
    
    private func observeAccountLogout() async {
        for await _ in notificationCenter.notifications(named: .accountDidLogout).map({ _ in () }) {
            guard !Task.isCancelled else { break }
            recentSearches.removeAll()
        }
    }
}
