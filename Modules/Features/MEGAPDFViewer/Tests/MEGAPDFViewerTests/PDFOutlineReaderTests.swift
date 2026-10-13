import Foundation
import PDFKit
@testable import MEGAPDFViewer
import os
import Testing

private struct RecordingNilPDFDocumentLoader: PDFDocumentLoading {
    // Synchronizes recorded URLs across actor calls.
    let requestedURLs = OSAllocatedUnfairLock(initialState: [URL]())

    func loadDocument(url: URL) -> PDFDocument? {
        requestedURLs.withLock { $0.append(url) }
        return nil
    }
}

struct PDFOutlineReaderTests {
    @Test func unreadableURL_returnsNoItems() async {
        let result = await PDFOutlineReader().outlineItems(
            forDocumentAt: URL(fileURLWithPath: "/tmp/missing.pdf"),
            documentLoader: PDFDocumentLoader()
        )

        #expect(result.inOutlineOrder.isEmpty)
        #expect(result.inPageOrder.isEmpty)
    }

    @Test func noOutlineRoot_returnsNoItems() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 3))

        #expect(result.inOutlineOrder.isEmpty)
        #expect(result.inPageOrder.isEmpty)
    }

    @Test func emptyOutlineRoot_returnsNoItems() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 3, outline: []))

        #expect(result.inOutlineOrder.isEmpty)
        #expect(result.inPageOrder.isEmpty)
    }

    @Test func nestedOutline_flattensDepthFirst() async throws {
        let result = await read(try nestedOutlineURL())

        #expect(result.inOutlineOrder.map(\.title) == ["A", "A1", "A1a", "B"])
        #expect(result.inOutlineOrder.map(\.level) == [0, 1, 2, 0])
        #expect(result.inOutlineOrder.map(\.pageIndex) == [0, 1, 2, 3])
    }

    @Test func nestedOutline_keysAreChildIndexPaths() async throws {
        let result = await read(try nestedOutlineURL())

        #expect(result.inOutlineOrder.map(\.id) == ["0", "0.0", "0.0.0", "1"])
    }

    @Test func deeperThanLimit_skipsDescendantsButKeepsRootSiblings() async throws {
        var chain = TestOutlineNode(label: "Level 64", pageIndex: 0)
        for level in (0..<64).reversed() {
            chain = TestOutlineNode(label: "Level \(level)", pageIndex: 0, children: [chain])
        }
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 1, outline: [
            chain,
            TestOutlineNode(label: "Sibling", pageIndex: 0)
        ]))

        #expect(result.inOutlineOrder.count == 65)
        #expect(result.inOutlineOrder[63].title == "Level 63")
        #expect(result.inOutlineOrder.last?.title == "Sibling")
    }

    @Test func unlabelledItem_isSkippedButChildrenKept() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 2, outline: [
            TestOutlineNode(label: nil, pageIndex: 0, children: [
                TestOutlineNode(label: "Child", pageIndex: 1)
            ])
        ]))

        #expect(result.inOutlineOrder == [
            PDFOutlineItem(id: "0.0", title: "Child", level: 1, pageIndex: 1)
        ])
    }

    @Test func emptyLabel_isSkipped() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 1, outline: [
            TestOutlineNode(label: "", pageIndex: 0)
        ]))

        #expect(result.inOutlineOrder.isEmpty)
        #expect(result.inPageOrder.isEmpty)
    }

    @Test func itemWithoutDestination_isSkipped() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 1, outline: [
            TestOutlineNode(label: "No destination")
        ]))

        #expect(result.inOutlineOrder.isEmpty)
        #expect(result.inPageOrder.isEmpty)
    }

    @Test func goToActionOnlyItem_resolvesItsPage() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 3, outline: [
            TestOutlineNode(label: "Go", pageIndex: 2, usesGoToAction: true)
        ]))

        #expect(result.inOutlineOrder.map(\.pageIndex) == [2])
    }

    @Test func injectedLoader_isUsedForValidURL() async throws {
        let url = try PDFDocument.makeTestDocumentURL(pageCount: 1)
        let loader = RecordingNilPDFDocumentLoader()
        let result = await PDFOutlineReader().outlineItems(
            forDocumentAt: url,
            documentLoader: loader
        )

        #expect(result.inOutlineOrder.isEmpty)
        #expect(result.inPageOrder.isEmpty)
        #expect(loader.requestedURLs.withLock { $0 } == [url])
    }

    @Test func outOfOrderPages_sortsStably() async throws {
        let result = await read(try PDFDocument.makeTestDocumentURL(pageCount: 31, outline: [
            TestOutlineNode(label: "0", pageIndex: 0),
            TestOutlineNode(label: "30", pageIndex: 30),
            TestOutlineNode(label: "10a", pageIndex: 10),
            TestOutlineNode(label: "10b", pageIndex: 10)
        ]))

        #expect(result.inOutlineOrder.map(\.pageIndex) == [0, 30, 10, 10])
        #expect(result.inPageOrder.map(\.pageIndex) == [0, 10, 10, 30])
        #expect(result.inPageOrder.map(\.id) == ["0", "2", "3", "1"])
    }

    private func read(_ url: URL) async -> PDFOutlineItems {
        await PDFOutlineReader().outlineItems(
            forDocumentAt: url,
            documentLoader: PDFDocumentLoader()
        )
    }

    private func nestedOutlineURL() throws -> URL {
        try PDFDocument.makeTestDocumentURL(pageCount: 4, outline: [
            TestOutlineNode(label: "A", pageIndex: 0, children: [
                TestOutlineNode(label: "A1", pageIndex: 1, children: [
                    TestOutlineNode(label: "A1a", pageIndex: 2)
                ])
            ]),
            TestOutlineNode(label: "B", pageIndex: 3)
        ])
    }
}
