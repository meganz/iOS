import PDFKit

protocol PDFDocumentUnlocking: Sendable {
    func unlock(document: PDFDocument, password: String) -> Bool
}

struct PDFDocumentUnlocker: PDFDocumentUnlocking {
    func unlock(document: PDFDocument, password: String) -> Bool {
        document.unlock(withPassword: password)
    }
}
