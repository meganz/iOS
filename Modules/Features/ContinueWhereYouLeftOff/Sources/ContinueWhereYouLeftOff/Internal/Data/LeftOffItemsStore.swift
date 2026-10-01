import Foundation
import MEGADomain
import MEGASwift
import SwiftData

package actor LeftOffItemsStore: LeftOffItemsStoreProtocol, ModelActor {
    package nonisolated let modelContainer: ModelContainer
    package nonisolated let modelExecutor: any ModelExecutor
    private let maxEntries: Int
    private var didPruneHistory = false

    private static let didChangeNotification = Notification.Name("mega.continuewhereyouleftoff.store.didChange")

    package init(storeURL: URL? = nil, inMemory: Bool = false, maxEntries: Int = 50) {
        let container = LeftOffItemsModelContainer.make(storeURL: storeURL, inMemory: inMemory)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        modelContainer = container
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.maxEntries = maxEntries
    }

    package func fetchItems(sortedBy key: LeftOffItemsSortKey, ascending: Bool, limit: Int) async throws -> [LeftOffItemEntity] {
        guard limit > 0 else { return [] }
        var descriptor = FetchDescriptor<LeftOffItemModel>(sortBy: [Self.sortDescriptor(for: key, ascending: ascending)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map(Self.toEntity)
    }

    /// Upserts by handle, then evicts the oldest rows beyond `maxEntries`.
    package func record(_ item: LeftOffItemEntity) async throws {
        let stored = Int64(bitPattern: item.handle)
        let maxEntries = maxEntries
        try write { context in
            if let existing = try Self.modelForHandle(stored, in: context) {
                existing.name = item.name
                existing.lastAccessed = item.lastAccessed
            } else {
                context.insert(LeftOffItemModel(
                    handle: stored,
                    name: item.name,
                    lastAccessed: item.lastAccessed
                ))
            }
            let all = try context.fetch(FetchDescriptor<LeftOffItemModel>(
                sortBy: [SortDescriptor(\.lastAccessed, order: .reverse)]
            ))
            for stale in all.dropFirst(maxEntries) { context.delete(stale) }
        }
    }

    package func remove(handles: [HandleEntity]) async throws {
        let stored = handles.map { Int64(bitPattern: $0) }
        try write { context in
            let descriptor = FetchDescriptor<LeftOffItemModel>(predicate: #Predicate { stored.contains($0.handle) })
            for model in try context.fetch(descriptor) { context.delete(model) }
        }
    }

    package func removeUnavailable(handle: HandleEntity) async throws {
        try await remove(handles: [handle])
    }

    package func clearHistory() async throws {
        try write { context in
            for model in try context.fetch(FetchDescriptor<LeftOffItemModel>()) { context.delete(model) }
        }
    }

    /// Emits a signal each time a write persists a change to stored rows (record, remove, removeUnavailable, clearHistory).
    /// A delete that matches no row emits nothing. A record always emits, because the upsert rewrites the row.
    /// The notification is scoped to this store instance, so parallel stores never cross-signal.
    package nonisolated func changesSignalSequence() -> AnyAsyncSequence<Void> {
        NotificationCenter.default
            .notifications(named: Self.didChangeNotification, object: self)
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }

    // MARK: - Helpers

    /// Runs the mutations as one transaction, rolling back on a thrown error, then signals if anything persisted.
    func write(_ block: @Sendable (ModelContext) throws -> Void) throws {
        pruneStaleHistory()
        var didChange = false
        do {
            try modelContext.transaction {
                try block(modelContext)
                didChange = modelContext.hasChanges
            }
        } catch {
            modelContext.rollback()
            throw error
        }
        if didChange { postChange() }
    }

    /// Purges accumulated persistent-history transactions once per store lifetime; CWYLO feature doesn't need this history
    /// This is only applicable for iOS 18 and later; earlier systems accumulate history that cannot be pruned.
    private func pruneStaleHistory() {
        guard #available(iOS 18, *), !didPruneHistory else { return }
        didPruneHistory = true
        guard modelContainer.configurations.contains(where: { !$0.isStoredInMemoryOnly }) else { return }
        try? modelContext.deleteHistory(HistoryDescriptor<DefaultHistoryTransaction>())
    }

    private static func modelForHandle(_ handle: Int64, in context: ModelContext) throws -> LeftOffItemModel? {
        var descriptor = FetchDescriptor<LeftOffItemModel>(predicate: #Predicate { $0.handle == handle })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private nonisolated func postChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    private static func sortDescriptor(for key: LeftOffItemsSortKey, ascending: Bool) -> SortDescriptor<LeftOffItemModel> {
        let order: SortOrder = ascending ? .forward : .reverse
        switch key {
        case .name:
            return SortDescriptor(\.name, comparator: .localizedStandard, order: order)
        case .lastAccessed:
            return SortDescriptor(\.lastAccessed, order: order)
        }
    }

    private static func toEntity(_ model: LeftOffItemModel) -> LeftOffItemEntity {
        LeftOffItemEntity(
            handle: HandleEntity(bitPattern: model.handle),
            name: model.name,
            lastAccessed: model.lastAccessed
        )
    }
}
