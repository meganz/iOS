import Foundation
import MEGAAppSDKRepo
import MEGASwift

/// Implements the Domain repository contract by wrapping the SwiftData data
/// source (`ViewedLinksStore`), and is the single boundary that maps a raw
/// persistence error to the Domain `ViewedLinkErrorEntity`.
package struct ViewedLinksRepository: ViewedLinksRepositoryProtocol {
    private let store: any ViewedLinksStoreProtocol

    package init(store: some ViewedLinksStoreProtocol) {
        self.store = store
    }

    package func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        try await perform { try await store.viewedLinks(sortedBy: sortKey, ascending: ascending) }
    }

    package func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        try await perform { try await store.topViewedLinks(limit: limit) }
    }

    package func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity) {
        try await perform { try await store.record(link) }
    }

    package func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity) {
        try await perform { try await store.remove(links) }
    }

    package func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity) {
        try await perform { try await store.removeUnavailable(linkURL: linkURL) }
    }

    package func clearHistory() async throws(ViewedLinkErrorEntity) {
        try await perform { try await store.clearHistory() }
    }

    package func changesSignalSequence() -> AnyAsyncSequence<Void> {
        store.changesSignalSequence()
    }

    private func perform<T>(_ operation: () async throws -> T) async throws(ViewedLinkErrorEntity) -> T {
        do {
            return try await operation()
        } catch is CancellationError {
            throw .cancelled
        } catch {
            MEGALogError("[ViewedLinks] Persistence operation failed: \(error)")
            throw .storeOperationFailed
        }
    }
}
