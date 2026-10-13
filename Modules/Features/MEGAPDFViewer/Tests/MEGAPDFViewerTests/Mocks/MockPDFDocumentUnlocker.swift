import Foundation
@testable import MEGAPDFViewer
import PDFKit

final class MockPDFDocumentUnlocker: PDFDocumentUnlocking, @unchecked Sendable {
    struct Invocation {
        let document: PDFDocument
        let password: String
    }

    private(set) var invocations: [Invocation] = []
    private(set) var isMainThreadInvocations: [Bool] = []
    var result: Bool
    var unlocksDocument = true

    init(result: Bool = false) {
        self.result = result
    }

    func unlock(document: PDFDocument, password: String) -> Bool {
        invocations.append(Invocation(document: document, password: password))
        isMainThreadInvocations.append(Thread.isMainThread)
        if result, unlocksDocument, let document = document as? MockLockablePDFDocument {
            document.locked = false
        }
        return result
    }
}

final class MockLockablePDFDocument: PDFDocument {
    var locked = true
    override var isLocked: Bool { locked }
    override var isEncrypted: Bool { true }
}

final class RecordingPDFDocumentLoader: PDFDocumentLoading, @unchecked Sendable {
    private var documents: [PDFDocument?]
    private(set) var urls: [URL] = []
    private(set) var isMainThreadInvocations: [Bool] = []

    init(documents: [PDFDocument?]) {
        self.documents = documents
    }

    func loadDocument(url: URL) -> PDFDocument? {
        urls.append(url)
        isMainThreadInvocations.append(Thread.isMainThread)
        return documents.isEmpty ? nil : documents.removeFirst()
    }
}
