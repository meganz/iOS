import PDFKit

struct PDFSearchMatch: Equatable {
    let selection: PDFSelection
    let pageIndex: Int
}

// `PDFDocumentSearcher` passes matches through an `AsyncStream`, which
// requires `Sendable`; `PDFSelection` is not, but matches are only created
// and read on the main actor.
extension PDFSearchMatch: @unchecked Sendable {}
