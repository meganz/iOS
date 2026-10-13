import Foundation
import PDFKit

struct PDFOutlineItem: Identifiable, Equatable, Sendable {
    typealias ItemID = String

    let id: ItemID
    let title: String
    let level: Int
    let pageIndex: Int
}

/// - `inOutlineOrder`: Outline items, listed in the PDF file metadata. May
///   not be sorted.
/// - `inPageOrder`: Outline lines, sorted by page (same-page items retain
///   ordering from PDF file metadata). Used to determine the outline item
///   nearest to the page the PDF viewer currently displays on screen.
struct PDFOutlineItems: Equatable, Sendable {
    let inOutlineOrder: [PDFOutlineItem]
    let inPageOrder: [PDFOutlineItem]
}

protocol PDFOutlineReading: Sendable {
    nonisolated func shouldLoadOutline(document: PDFDocument) -> Bool
    /// Returns the PDF outline in outline order and stable page order.
    /// - Skips items with no label or no destination page, but keeps their
    ///   children, and returns no items when document loading fails.
    func outlineItems(
        forDocumentAt url: URL,
        documentLoader: some PDFDocumentLoading,
        unlockPassword: String?
    ) async -> PDFOutlineItems
}

struct PDFOutlineReader: PDFOutlineReading {
    private let documentUnlocker: any PDFDocumentUnlocking

    init(documentUnlocker: some PDFDocumentUnlocking = PDFDocumentUnlocker()) {
        self.documentUnlocker = documentUnlocker
    }

    nonisolated func shouldLoadOutline(document: PDFDocument) -> Bool {
        (document.outlineRoot?.numberOfChildren ?? 0) > 0
    }

    @concurrent
    nonisolated func outlineItems(
        forDocumentAt url: URL,
        documentLoader: some PDFDocumentLoading,
        unlockPassword: String? = nil
    ) async -> PDFOutlineItems {
        guard !Task.isCancelled,
              let document = documentLoader.loadDocument(url: url)
        else {
            return PDFOutlineItems(inOutlineOrder: [], inPageOrder: [])
        }

        if document.isLocked {
            guard let unlockPassword,
                  documentUnlocker.unlock(document: document, password: unlockPassword),
                  !document.isLocked else {
                return PDFOutlineItems(inOutlineOrder: [], inPageOrder: [])
            }
        }
        guard let outlineRoot = document.outlineRoot else {
            return PDFOutlineItems(inOutlineOrder: [], inPageOrder: [])
        }

        var inOutlineOrder: [PDFOutlineItem] = []
        appendItems(
            in: outlineRoot,
            document: document,
            level: 0,
            path: [],
            to: &inOutlineOrder
        )
        guard !Task.isCancelled else {
            return PDFOutlineItems(inOutlineOrder: [], inPageOrder: [])
        }
        return PDFOutlineItems(
            inOutlineOrder: inOutlineOrder,
            inPageOrder: inOutlineOrder.sorted { $0.pageIndex < $1.pageIndex }
        )
    }

    /// Collect the outline of the `PDFDocument` into the `items` array.
    /// Uses DFS to ensure outline items are nested correctly.
    private func appendItems(
        in outline: PDFOutline,
        document: PDFDocument,
        level: Int,
        path: [Int],
        to items: inout [PDFOutlineItem]
    ) {
        for index in 0..<outline.numberOfChildren {
            guard !Task.isCancelled else { return }
            guard let child = outline.child(at: index) else { continue }
            // Bound stack use when a PDF contains unusually deep nesting.
            guard level < 64 else { continue }
            let childPath = path + [index]

            appendItem(
                child,
                document: document,
                level: level,
                path: childPath,
                to: &items
            )
            appendItems(
                in: child,
                document: document,
                level: level + 1,
                path: childPath,
                to: &items
            )
        }
    }

    private func appendItem(
        _ outline: PDFOutline,
        document: PDFDocument,
        level: Int,
        path: [Int],
        to items: inout [PDFOutlineItem]
    ) {
        guard let label = outline.label,
              !label.isEmpty,
              let page = outline.destination?.page
        else { return }
        let pageIndex = document.index(for: page)
        guard (0..<document.pageCount).contains(pageIndex) else { return }
        items.append(
            PDFOutlineItem(
                id: path.map(String.init).joined(separator: "."),
                title: label,
                level: level,
                pageIndex: pageIndex
            )
        )
    }
}
