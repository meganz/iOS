import Foundation
import MEGADomain
import MEGASwift
import SwiftData

package actor ViewedLinksStore: ViewedLinksStoreProtocol, ModelActor {
    package nonisolated let modelContainer: ModelContainer
    package nonisolated let modelExecutor: any ModelExecutor
    private let maxEntries: Int
    private var didPruneHistory = false

    private static let didChangeNotification = Notification.Name("mega.viewedlinks.store.didChange")

    package init(storeURL: URL? = nil, inMemory: Bool = false, maxEntries: Int = 100) {
        let container = ViewedLinksModelContainer.make(storeURL: storeURL, inMemory: inMemory)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        modelContainer = container
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.maxEntries = maxEntries
    }

    package func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws -> [ViewedLinkEntity] {
        let descriptor = FetchDescriptor<ViewedLinkModel>(sortBy: [Self.sortDescriptor(for: sortKey, ascending: ascending)])
        return try modelContext.fetch(descriptor).map(Self.toEntity)
    }

    package func topViewedLinks(limit: Int) async throws -> [ViewedLinkEntity] {
        guard limit > 0 else { return [] }
        var descriptor = FetchDescriptor<ViewedLinkModel>(sortBy: [SortDescriptor(\.lastAccessed, order: .reverse)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map(Self.toEntity)
    }

    /// Upserts by handle, then evicts the oldest rows beyond `maxEntries`.
    package func record(_ link: ViewedLinkEntity) async throws {
        let stored = Int64(bitPattern: link.handle)
        let maxEntries = maxEntries
        try write { context in
            if let existing = try Self.modelForHandle(stored, in: context) {
                existing.linkURL = link.linkURL.absoluteString
                existing.name = link.name
                existing.isFolder = link.isFolder
                existing.lastAccessed = link.lastAccessed
            } else {
                context.insert(ViewedLinkModel(
                    handle: stored,
                    linkURL: link.linkURL.absoluteString,
                    name: link.name,
                    isFolder: link.isFolder,
                    lastAccessed: link.lastAccessed
                ))
            }
            let all = try context.fetch(FetchDescriptor<ViewedLinkModel>(
                sortBy: [SortDescriptor(\.lastAccessed, order: .reverse)]
            ))
            for stale in all.dropFirst(maxEntries) { context.delete(stale) }
        }
    }

    package func remove(_ links: [ViewedLinkEntity]) async throws {
        let handles = links.map { Int64(bitPattern: $0.handle) }
        try write { context in
            let descriptor = FetchDescriptor<ViewedLinkModel>(predicate: #Predicate { handles.contains($0.handle) })
            for model in try context.fetch(descriptor) { context.delete(model) }
        }
    }

    package func removeUnavailable(linkURL: URL) async throws {
        let urlString = linkURL.absoluteString
        try write { context in
            let descriptor = FetchDescriptor<ViewedLinkModel>(predicate: #Predicate { $0.linkURL == urlString })
            for model in try context.fetch(descriptor) { context.delete(model) }
        }
    }

    package func clearHistory() async throws {
        try write { context in
            for model in try context.fetch(FetchDescriptor<ViewedLinkModel>()) { context.delete(model) }
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

    /// Purges accumulated persistent-history transactions once per store lifetime; nothing here consumes history tokens.
    /// Available on iOS 18 and later; earlier systems accrue history that this store never reads.
    private func pruneStaleHistory() {
        guard #available(iOS 18, *), !didPruneHistory else { return }
        didPruneHistory = true
        try? modelContext.deleteHistory(HistoryDescriptor<DefaultHistoryTransaction>())
    }

    private static func modelForHandle(_ handle: Int64, in context: ModelContext) throws -> ViewedLinkModel? {
        var descriptor = FetchDescriptor<ViewedLinkModel>(predicate: #Predicate { $0.handle == handle })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private nonisolated func postChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    private static func sortDescriptor(for key: ViewedLinksSortKey, ascending: Bool) -> SortDescriptor<ViewedLinkModel> {
        let order: SortOrder = ascending ? .forward : .reverse
        switch key {
        case .name:
            return SortDescriptor(\.name, comparator: .localizedStandard, order: order)
        case .lastAccessed:
            return SortDescriptor(\.lastAccessed, order: order)
        }
    }

    private static func toEntity(_ model: ViewedLinkModel) -> ViewedLinkEntity {
        ViewedLinkEntity(
            handle: HandleEntity(bitPattern: model.handle),
            linkURL: URL(string: model.linkURL) ?? URL(fileURLWithPath: "/"),
            name: model.name,
            isFolder: model.isFolder,
            lastAccessed: model.lastAccessed
        )
    }
}
