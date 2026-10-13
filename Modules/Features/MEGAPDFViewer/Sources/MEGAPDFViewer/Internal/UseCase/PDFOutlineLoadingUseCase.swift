import Foundation
import PDFKit

protocol PDFOutlineLoadingUseCaseProtocol: Sendable {
    func hasOutline(document: PDFDocument) -> Bool
    func loadOutline(documentURL: URL) async -> PDFOutlineItems
}

struct PDFOutlineLoadingUseCase: PDFOutlineLoadingUseCaseProtocol {
    private let documentLoader: any PDFDocumentLoading
    private let outlineReader: any PDFOutlineReading

    init(documentLoader: some PDFDocumentLoading, outlineReader: some PDFOutlineReading) {
        self.documentLoader = documentLoader
        self.outlineReader = outlineReader
    }

    func hasOutline(document: PDFDocument) -> Bool {
        outlineReader.shouldLoadOutline(document: document)
    }

    func loadOutline(documentURL: URL) async -> PDFOutlineItems {
        await outlineReader.outlineItems(
            forDocumentAt: documentURL,
            documentLoader: documentLoader
        )
    }
}
