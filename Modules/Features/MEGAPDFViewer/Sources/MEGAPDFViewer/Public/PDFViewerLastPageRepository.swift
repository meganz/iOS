public protocol PDFViewerLastPageRepositoryProtocol: Sendable {
    /// The 0-based page to resume at for `documentIdentifier`, or nil if
    /// there is nothing to resume.
    func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int?

    /// Persists the 0-based last-viewed page for `documentIdentifier`.
    func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async

    func deleteLastPageIndex(forDocumentIdentifier documentIdentifier: String) async
}

/// Stores pages as 1-based `MEGAStore` media destinations, the format the
/// legacy viewer reads and writes.
@MainActor
public final class PDFViewerLastPageRepository: PDFViewerLastPageRepositoryProtocol {
    private let store: any PDFViewerLastPageMEGAStoreProtocol

    public init(store: some PDFViewerLastPageMEGAStoreProtocol) {
        self.store = store
    }

    public func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int? {
        guard let destination = store.fetchLastPageDestination(forFingerprint: documentIdentifier),
              destination > 1 else { return nil }
        return destination - 1
    }

    public func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async {
        store.saveLastPageDestination(index + 1, forFingerprint: documentIdentifier)
    }

    public func deleteLastPageIndex(forDocumentIdentifier documentIdentifier: String) async {
        store.deleteLastPageDestination(forFingerprint: documentIdentifier)
    }
}
