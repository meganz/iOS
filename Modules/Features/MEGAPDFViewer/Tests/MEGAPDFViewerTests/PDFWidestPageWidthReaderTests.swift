import CoreGraphics
@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

struct PageBoxFixture: CustomTestStringConvertible, Sendable {
    var mediaSize: CGSize
    var cropBox: CGRect?
    var rotation = 0

    var testDescription: String {
        "media \(mediaSize.width)x\(mediaSize.height)"
            + (cropBox.map { " crop \($0.width)x\($0.height)" } ?? "")
            + (rotation == 0 ? "" : " rotated \(rotation)")
    }
}

struct PageBoxDocumentFixture: CustomTestStringConvertible, Sendable {
    let pages: [PageBoxFixture]
    let displayBox: PDFDisplayBox
    let expectedWidestPageWidth: CGFloat

    var testDescription: String {
        pages.map(\.testDescription).joined(separator: " + ")
            + (displayBox == .cropBox ? " in crop box" : " in media box")
    }
}

private let documentFixtures = [
    PageBoxDocumentFixture(
        pages: [PageBoxFixture(mediaSize: CGSize(width: 300, height: 300), cropBox: CGRect(x: 100, y: 100, width: 100, height: 100))],
        displayBox: .cropBox,
        expectedWidestPageWidth: 100
    ),
    PageBoxDocumentFixture(
        pages: [PageBoxFixture(mediaSize: CGSize(width: 300, height: 300), cropBox: CGRect(x: 100, y: 100, width: 100, height: 100))],
        displayBox: .mediaBox,
        expectedWidestPageWidth: 300
    ),
    PageBoxDocumentFixture(
        pages: [
            PageBoxFixture(mediaSize: CGSize(width: 200, height: 200)),
            PageBoxFixture(mediaSize: CGSize(width: 400, height: 400), cropBox: CGRect(x: 0, y: 0, width: 100, height: 400))
        ],
        displayBox: .cropBox,
        expectedWidestPageWidth: 200
    ),
    PageBoxDocumentFixture(
        pages: [
            PageBoxFixture(mediaSize: CGSize(width: 400, height: 1000)),
            PageBoxFixture(mediaSize: CGSize(width: 600, height: 100))
        ],
        displayBox: .cropBox,
        expectedWidestPageWidth: 600
    ),
    PageBoxDocumentFixture(
        pages: [
            PageBoxFixture(mediaSize: CGSize(width: 200, height: 200)),
            PageBoxFixture(mediaSize: CGSize(width: 100, height: 300), rotation: 90),
            PageBoxFixture(mediaSize: CGSize(width: 50, height: 250), rotation: 270)
        ],
        displayBox: .cropBox,
        expectedWidestPageWidth: 300
    ),
    PageBoxDocumentFixture(
        pages: [PageBoxFixture(mediaSize: CGSize(width: 10, height: 10), cropBox: CGRect(x: 2, y: 3, width: 3.84, height: 3.84))],
        displayBox: .cropBox,
        expectedWidestPageWidth: 3.84
    )
]

struct PDFWidestPageWidthReaderTests {
    @Test(arguments: documentFixtures)
    @MainActor
    func readsWidestPageInDisplayBox(fixture: PageBoxDocumentFixture) async throws {
        nonisolated(unsafe) let document: CGPDFDocument? = try makeDocument(fixture.pages)

        let width = await PDFWidestPageWidthReader().widestPageWidth(of: document, in: fixture.displayBox)

        #expect(abs(width - fixture.expectedWidestPageWidth) < 0.0001)
    }

    @Test
    func readsUnlockedEncryptedDocumentThroughItsOwnCoreGraphicsDocument() async throws {
        let url = try #require(Bundle.module.url(forResource: "locked-rc4", withExtension: "pdf", subdirectory: "Fixtures"))
        let pdfDocument = try #require(PDFDocument(url: url))
        try #require(pdfDocument.unlock(withPassword: "secret"))
        let document = try #require(pdfDocument.documentRef)

        let width = await PDFWidestPageWidthReader().widestPageWidth(of: document, in: .cropBox)

        #expect(width == 612)
    }

    @Test
    @MainActor
    func cancelledTaskDoesNotReadPageWidths() async throws {
        nonisolated(unsafe) let document: CGPDFDocument? = try makeDocument([PageBoxFixture(mediaSize: CGSize(width: 100, height: 100))])

        let width = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await PDFWidestPageWidthReader().widestPageWidth(of: document, in: .cropBox)
        }.value

        #expect(width == 0)
    }

    // Crops and rotations are written into the file through PDFKit, then the
    // file is reopened, so the reader sees what a PDF on disk would declare.
    @MainActor
    private func makeDocument(_ pages: [PageBoxFixture]) throws -> CGPDFDocument {
        let data = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pages[0].mediaSize)).pdfData { context in
            for page in pages {
                context.beginPage(withBounds: CGRect(origin: .zero, size: page.mediaSize), pageInfo: [:])
            }
        }
        let editable = try #require(PDFDocument(data: data))
        for (index, page) in pages.enumerated() {
            let pdfPage = try #require(editable.page(at: index))
            if let cropBox = page.cropBox { pdfPage.setBounds(cropBox, for: .cropBox) }
            pdfPage.rotation = page.rotation
        }
        let edited = try #require(editable.dataRepresentation())
        let provider = try #require(CGDataProvider(data: edited as CFData))
        return try #require(CGPDFDocument(provider))
    }
}
