@testable import MEGAPDFViewer

final class MockPDFViewerLastPageMEGAStore: PDFViewerLastPageMEGAStoreProtocol {
    enum Invocation: Equatable {
        case fetchLastPageDestination(fingerprint: String)
        case saveLastPageDestination(destination: Int, fingerprint: String)
        case deleteLastPageDestination(fingerprint: String)
    }

    private(set) var invocations: [Invocation] = []
    private let fetchLastPageDestinationResult: Int?

    init(fetchLastPageDestinationResult: Int? = nil) {
        self.fetchLastPageDestinationResult = fetchLastPageDestinationResult
    }

    func fetchLastPageDestination(forFingerprint fingerprint: String) -> Int? {
        invocations.append(.fetchLastPageDestination(fingerprint: fingerprint))
        return fetchLastPageDestinationResult
    }

    func saveLastPageDestination(_ destination: Int, forFingerprint fingerprint: String) {
        invocations.append(.saveLastPageDestination(destination: destination, fingerprint: fingerprint))
    }

    func deleteLastPageDestination(forFingerprint fingerprint: String) {
        invocations.append(.deleteLastPageDestination(fingerprint: fingerprint))
    }
}
