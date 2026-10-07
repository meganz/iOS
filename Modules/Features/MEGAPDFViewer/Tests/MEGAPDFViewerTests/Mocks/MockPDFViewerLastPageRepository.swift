@testable import MEGAPDFViewer

@MainActor
final class MockPDFViewerLastPageRepository: PDFViewerLastPageRepositoryProtocol {
    enum Invocation: Equatable {
        case loadLastPageIndex(documentIdentifier: String)
        case saveLastPageIndex(index: Int, documentIdentifier: String)
        case deleteLastPageIndex(documentIdentifier: String)
    }

    private(set) var invocations: [Invocation] = []
    private let loadLastPageIndexResult: Int?

    init(loadLastPageIndexResult: Int? = nil) {
        self.loadLastPageIndexResult = loadLastPageIndexResult
    }

    func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int? {
        invocations.append(.loadLastPageIndex(documentIdentifier: documentIdentifier))
        return loadLastPageIndexResult
    }

    func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async {
        invocations.append(.saveLastPageIndex(index: index, documentIdentifier: documentIdentifier))
    }

    func deleteLastPageIndex(forDocumentIdentifier documentIdentifier: String) async {
        invocations.append(.deleteLastPageIndex(documentIdentifier: documentIdentifier))
    }
}
