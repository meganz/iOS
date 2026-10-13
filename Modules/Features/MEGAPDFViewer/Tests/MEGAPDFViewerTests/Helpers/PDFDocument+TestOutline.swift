import Foundation
import PDFKit

struct TestOutlineNode {
    var label: String?
    var pageIndex: Int?
    var usesGoToAction = false
    var children: [TestOutlineNode] = []
}

extension PDFDocument {
    static func makeTestDocumentURL(
        pageCount: Int,
        outline: [TestOutlineNode]? = nil,
        password: String? = nil
    ) throws -> URL {
        let document = PDFDocument()
        for index in 0..<pageCount {
            document.insert(PDFPage(), at: index)
        }
        if let outline {
            let root = PDFOutline()
            insertTestOutline(outline, into: root, document: document)
            document.outlineRoot = root
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        let options: [PDFDocumentWriteOption: Any] = password.map {
            [.userPasswordOption: $0, .ownerPasswordOption: UUID().uuidString]
        } ?? [:]
        guard document.write(to: url, withOptions: options) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return url
    }

    private static func insertTestOutline(
        _ nodes: [TestOutlineNode],
        into parent: PDFOutline,
        document: PDFDocument
    ) {
        for (index, node) in nodes.enumerated() {
            let item = PDFOutline()
            item.label = node.label
            if let pageIndex = node.pageIndex,
               let page = document.page(at: pageIndex) {
                let destination = PDFDestination(page: page, at: .zero)
                if node.usesGoToAction {
                    item.action = PDFActionGoTo(destination: destination)
                } else {
                    item.destination = destination
                }
            }
            parent.insertChild(item, at: index)
            insertTestOutline(node.children, into: item, document: document)
        }
    }
}
