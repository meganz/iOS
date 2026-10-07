import Foundation
@testable import MEGAPDFViewer

@MainActor
final class MockPDFViewerLastPageUseCase: PDFViewerLastPageUseCaseProtocol {
    enum Invocation: Equatable {
        case documentIdentifierForLastViewedPageIndex(url: URL)
        case loadLastPageIndex(documentIdentifier: String)
        case saveLastPageIndex(index: Int, documentIdentifier: String)
    }

    private(set) var invocations: [Invocation] = []
    private let documentIdentifierForLastViewedPageIndexResult: String?
    private let loadLastPageIndexResult: Int?

    init(
        documentIdentifierForLastViewedPageIndexResult: String? = "any-fingerprint",
        loadLastPageIndexResult: Int? = nil
    ) {
        self.documentIdentifierForLastViewedPageIndexResult = documentIdentifierForLastViewedPageIndexResult
        self.loadLastPageIndexResult = loadLastPageIndexResult
    }

    func documentIdentifierForLastViewedPageIndex(forDocumentAt url: URL) async -> String? {
        invocations.append(.documentIdentifierForLastViewedPageIndex(url: url))
        return documentIdentifierForLastViewedPageIndexResult
    }

    func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int? {
        invocations.append(.loadLastPageIndex(documentIdentifier: documentIdentifier))
        return loadLastPageIndexResult
    }

    func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async {
        invocations.append(.saveLastPageIndex(index: index, documentIdentifier: documentIdentifier))
    }
}
