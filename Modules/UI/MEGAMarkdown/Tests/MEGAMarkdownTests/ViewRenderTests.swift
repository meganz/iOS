@testable import MEGAMarkdown
import SwiftUI
import Testing

/// Smoke tests: every block kind renders to a real image with a non-zero size and visible pixels.
@MainActor
@Suite struct ViewRenderTests {
    nonisolated private static func block(_ id: Int, _ kind: MarkdownBlock.Kind) -> MarkdownBlock {
        MarkdownBlock(id: id, sourceLine: id, kind: kind)
    }

    nonisolated static let allKindsDocument: MarkdownDocument = {
        let link = (try? AttributedString(markdown: "A [link](https://mega.io), **bold**, `code`, ~~strike~~."))
            ?? AttributedString("link")
        let table = MarkdownTable(
            columns: [.init(alignment: .left), .init(alignment: .center), .init(alignment: .right)],
            header: ["Name", "Size", "Type"],
            rows: [["a.md", "1 KB", "Text"], ["b.png", "2 MB"]]
        )
        let nestedList = MarkdownList(isOrdered: false, startIndex: 1, items: [
            MarkdownListItem(blocks: [block(10, .paragraph("Nested"))])
        ])
        let list = MarkdownList(isOrdered: true, startIndex: 3, items: [
            MarkdownListItem(blocks: [block(7, .paragraph("Three")), block(9, .list(nestedList))]),
            MarkdownListItem(checkbox: .checked, blocks: [block(11, .paragraph("Done"))]),
            MarkdownListItem(checkbox: .unchecked, blocks: [block(12, .paragraph("Todo"))])
        ])
        return MarkdownDocument(blocks: [
            block(0, .heading(level: 1, text: "Title")),
            block(1, .heading(level: 6, text: "Small")),
            block(2, .paragraph(link)),
            block(3, .codeBlock(language: "swift", code: "let x = 1\nprint(x)")),
            block(4, .blockQuote([block(5, .paragraph("Quoted"))])),
            block(6, .list(list)),
            block(13, .table(table)),
            block(14, .thematicBreak),
            // A local file that does not exist: the remote-image path runs without any network.
            block(15, .image(url: URL(string: "file:///nonexistent/a.png"), altText: "Alt text"))
        ])
    }()

    private func renderSize(_ view: some View) throws -> CGSize {
        let image = try render(view)
        return CGSize(width: image.width, height: image.height)
    }

    private func render(_ view: some View) throws -> CGImage {
        let renderer = ImageRenderer(content: view.frame(width: 390))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    /// A size alone passes for an empty image. Something must be drawn: at least one pixel is not clear.
    private func drawsSomething(_ image: CGImage) -> Bool {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return false }
        return stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] > 0 }
    }

    /// The text init parses on draw. It must draw the same as the parsed document.
    @Test func markdownTextRendersLikeItsParsedDocument() throws {
        let text = "# Title\n\nSome **bold** text.\n\n- item"
        let baseURL = URL(string: "https://mega.io")
        let fromText = try renderSize(MarkdownView(text, baseURL: baseURL, softBreak: .space))
        let document = MarkdownParser.parse(text, baseURL: baseURL, softBreak: .space)
        try #require(document.blocks.count == 3)
        #expect(fromText == (try renderSize(MarkdownView(document: document))))
    }

    @Test func documentWithEveryBlockKindRenders() throws {
        let image = try render(MarkdownView(document: Self.allKindsDocument))
        #expect(image.width == 390)
        #expect(image.height > 200)
        #expect(drawsSomething(image))
    }

    @Test(arguments: allKindsDocument.blocks)
    func eachBlockKindRenders(block: MarkdownBlock) throws {
        let image = try render(MarkdownView(document: MarkdownDocument(blocks: [block])))
        #expect(image.width == 390)
        #expect(image.height > 0)
        // ImageRenderer draws no ScrollView content, and the whole table sits in one. The table snapshot covers its look.
        if case .table = block.kind { return }
        #expect(drawsSomething(image), "block \(block.id) draws nothing")
    }

    @Test func customThemeAndRemoteImagesRender() throws {
        var theme = MarkdownTheme.default
        theme.blockSpacing = 24
        theme.linkColor = .purple
        let view = MarkdownView(document: Self.allKindsDocument)
            .markdownTheme(theme)
            .markdownImageLoading(.remote)
        let size = try renderSize(view)
        #expect(size.height > 200)
        // The theme reaches the view: each of the 8 gaps between the 9 top-level blocks grows.
        let plain = try renderSize(MarkdownView(document: Self.allKindsDocument))
        let growth = (theme.blockSpacing - MarkdownTheme.default.blockSpacing) * 8
        #expect(growth > 0)
        #expect(size.height >= plain.height + growth - 1, "custom \(size.height) default \(plain.height)")
    }

    /// Crash check only. `ViewLogicTests` checks the split itself.
    @Test func paragraphOverTheMeasureLimitRenders() throws {
        let long = AttributedString(String(repeating: "word ", count: 12_000))
        let size = try renderSize(MarkdownView(document: MarkdownDocument(blocks: [Self.block(0, .paragraph(long))])))
        #expect(size.height > 1_000)
    }

    /// Each code span adds two `Text` pieces. 10,000 spans must render without a stack overflow.
    @Test func paragraphWithManyCodeSpansDoesNotOverflowTheStack() throws {
        let text = try AttributedString(markdown: String(repeating: "`a` ", count: 10_000))
        let size = try renderSize(MarkdownView(document: MarkdownDocument(blocks: [Self.block(0, .paragraph(text))])))
        #expect(size.height > 1_000)
    }
}
