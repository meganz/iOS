@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@Suite(.serialized)
@MainActor
struct PDFSearchHighlightOverlayProviderTests {
    // MARK: - Drawing

    @Test func appendedMatch_drawsOnlyOnItsPage() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one", "alpha two"])
        let matches = try fixture.matches("alpha")

        fixture.provider.show([matches[0]], highlightedIndex: nil, dims: true)

        #expect(try fixture.overlay(onPage: 0).boxes.count == 1)
        #expect(try fixture.overlay(onPage: 1).boxes.isEmpty)
    }

    @Test func matchesShown_dimEveryShownPage() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one", "no match here"])
        let matches = try fixture.matches("alpha")

        fixture.provider.show(matches, highlightedIndex: nil, dims: true)

        #expect(try fixture.overlay(onPage: 0).isDimmed)
        #expect(try fixture.overlay(onPage: 1).isDimmed)
    }

    @Test func matchesReplacedWhileDimmed_keepPagesDimmed() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)

        fixture.provider.show([], highlightedIndex: nil, dims: true)

        let overlay = try fixture.overlay(onPage: 0)
        #expect(overlay.isDimmed)
        #expect(overlay.boxes.isEmpty)
    }

    @Test func searchCleared_removesTheDimming() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)

        fixture.provider.show([], highlightedIndex: nil, dims: false)

        let overlay = try fixture.overlay(onPage: 0)
        #expect(!overlay.isDimmed)
        #expect(overlay.boxes.isEmpty)
    }

    @Test func highlightedMatch_isYellowAndOthersUndimmed() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one alpha two"])
        let matches = try fixture.matches("alpha")
        try #require(matches.count == 2)

        fixture.provider.show(matches, highlightedIndex: 1, dims: true)

        let overlay = try fixture.overlay(onPage: 0)
        let highlighted = try #require(overlay.boxes.first { $0.isHighlighted })
        let found = try #require(overlay.boxes.first(where: { !$0.isHighlighted }))
        #expect(highlighted.matchIndex == 1)
        let highlightedLayer = try #require(overlay.highlightedBoxLayers.first)
        #expect(try cornerColour(of: highlightedLayer).isClose(to: PDFSearchHighlightOverlayView.highlightedColor))
        #expect(try dimAlpha(of: overlay, at: CGPoint(x: found.frame.midX, y: found.frame.midY)) == 0)
        #expect(try dimAlpha(of: overlay, at: CGPoint(x: found.frame.midX, y: found.frame.maxY + 20)) > 0)
    }

    @Test func matchBox_keepsItsGlyphsDarkOverItsFill() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])

        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)

        let boxLayer = try #require(try fixture.overlay(onPage: 0).highlightedBoxLayers.first)
        let pixels = try rgbPixels(of: boxLayer)
        #expect(pixels.contains { $0.r < 0.3 && $0.g < 0.3 && $0.b < 0.3 })
        #expect(pixels.contains { $0.isClose(to: PDFSearchHighlightOverlayView.highlightedColor) })
    }

    @Test func wrappedMatch_highlightsOnlyItsTextOnEachLine() async throws {
        let fixture = try await OverlayFixture(pages: ["filler words soft-\nware and more"])
        let document = try #require(fixture.base.pdfView.document)
        let first = try #require(document.findString("soft-", withOptions: []).first)
        let second = try #require(document.findString("ware", withOptions: []).first)
        let wrapped = try #require(first.copy() as? PDFSelection)
        wrapped.add(second)
        try #require(wrapped.selectionsByLine().count == 2)
        let page = try #require(document.page(at: 0))

        fixture.provider.show([PDFSearchMatch(selection: wrapped, pageIndex: 0)], highlightedIndex: nil, dims: true)

        let overlay = try fixture.overlay(onPage: 0)
        #expect(overlay.boxes.count == 2)
        let wholeWidth = wrapped.bounds(for: page).width * overlay.bounds.width / page.bounds(for: .cropBox).width
        #expect(overlay.boxes.allSatisfy { $0.frame.width < wholeWidth / 2 })
    }

    @Test func wrappedHighlightedMatch_leavesNoBoxBehindAfterRelayoutOrMove() async throws {
        let fixture = try await OverlayFixture(pages: ["filler words soft-\nware and more"])
        let document = try #require(fixture.base.pdfView.document)
        let first = try #require(document.findString("soft-", withOptions: []).first)
        let second = try #require(document.findString("ware", withOptions: []).first)
        let wrapped = try #require(first.copy() as? PDFSelection)
        wrapped.add(second)
        try #require(wrapped.selectionsByLine().count == 2)
        let match = PDFSearchMatch(selection: wrapped, pageIndex: 0)
        let overlay = try fixture.overlay(onPage: 0)
        fixture.provider.show([match], highlightedIndex: 0, dims: true)
        overlay.layoutIfNeeded()

        overlay.setNeedsLayout()
        overlay.layoutIfNeeded()
        // The dimming layer plus one highlighted box per line.
        #expect(overlay.layer.sublayers?.count == 3)
        fixture.provider.show([match], highlightedIndex: nil, dims: true)
        overlay.layoutIfNeeded()

        #expect(overlay.layer.sublayers?.count == 1)
    }

    @Test func highlightMove_recoloursOnlyOldAndNewPages() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one", "alpha two", "alpha three"])
        let matches = try fixture.matches("alpha")
        fixture.provider.show(matches, highlightedIndex: 0, dims: true)
        let overlays = try (0..<3).map { try fixture.overlay(onPage: $0) }
        let countsBefore = overlays.map(\.updateCount)

        fixture.provider.show(matches, highlightedIndex: 1, dims: true)

        let changes = zip(overlays.map(\.updateCount), countsBefore).map { $0 - $1 }
        #expect(changes == [1, 1, 0])
    }

    @Test func newSearch_clearsEveryPage() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one", "alpha two"])
        let matches = try fixture.matches("alpha")
        fixture.provider.show(matches, highlightedIndex: 0, dims: true)

        fixture.provider.show([], highlightedIndex: nil, dims: false)
        fixture.provider.show([matches[1]], highlightedIndex: nil, dims: true)

        #expect(try fixture.overlay(onPage: 0).boxes.isEmpty)
        #expect(try fixture.overlay(onPage: 1).boxes.count == 1)
    }

    @Test(arguments: [1.0, 2.0])
    func highlightRect_matchesPDFKitRect(zoom: CGFloat) async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"], cropInset: 40)
        let pdfView = fixture.base.pdfView
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit * zoom
        let match = try #require(try fixture.matches("alpha").first)
        let page = try #require(match.selection.pages.first)
        fixture.provider.show([match], highlightedIndex: 0, dims: true)
        pdfView.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(200))

        let overlay = try #require(pdfView.searchHighlightOverlayViews.first { !$0.boxes.isEmpty })
        let box = try #require(overlay.boxes.first)
        let drawn = overlay.convert(box.frame, to: pdfView)
        let padding = PDFSearchHighlightOverlayView.padding
        let expected = pdfView.convert(
            match.selection.bounds(for: page).insetBy(dx: -padding.width, dy: -padding.height),
            from: page
        )
        #expect(abs(drawn.minX - expected.minX) < 0.5)
        #expect(abs(drawn.minY - expected.minY) < 0.5)
        #expect(abs(drawn.width - expected.width) < 0.5)
        #expect(abs(drawn.height - expected.height) < 0.5)
    }

    @Test(arguments: [0, 90, 180, 270])
    func highlightOnRotatedPage_coversItsMatchAndShowsItsGlyphs(rotation: Int) async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        let pdfView = fixture.base.pdfView
        let page = try #require(pdfView.document?.page(at: 0))
        page.rotation = rotation
        pdfView.layoutDocumentView()
        pdfView.layoutIfNeeded()
        let match = try #require(try fixture.matches("alpha").first)
        fixture.provider.show([match], highlightedIndex: 0, dims: true)
        pdfView.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(200))

        let overlay = try #require(pdfView.searchHighlightOverlayViews.first { !$0.boxes.isEmpty })
        let box = try #require(overlay.boxes.first)
        let drawn = overlay.convert(box.frame, to: pdfView)
        let padding = PDFSearchHighlightOverlayView.padding
        let expected = pdfView.convert(
            match.selection.bounds(for: page).insetBy(dx: -padding.width, dy: -padding.height),
            from: page
        )
        #expect(abs(drawn.midX - expected.midX) < 0.5)
        #expect(abs(drawn.midY - expected.midY) < 0.5)
        #expect(abs(drawn.width - expected.width) < 0.5)
        #expect(abs(drawn.height - expected.height) < 0.5)
        let boxLayer = try #require(overlay.highlightedBoxLayers.first)
        #expect(try rgbPixels(of: boxLayer).contains { $0.r < 0.3 && $0.g < 0.3 && $0.b < 0.3 })
    }

    // MARK: - Lifecycle

    @Test func recreatedOverlayView_startsFromStoredHighlights() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)
        _ = try fixture.overlay(onPage: 0)

        let recreated = try fixture.overlay(onPage: 0)

        #expect(recreated.boxes.count == 1)
        #expect(recreated.isDimmed)
    }

    @Test func overlayView_ignoresTouches() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])

        #expect(try !fixture.overlay(onPage: 0).isUserInteractionEnabled)
    }

    // MARK: - Pop

    @Test func newHighlightedMatch_popsOnce() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        let overlay = try fixture.overlay(onPage: 0)

        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)
        overlay.layoutIfNeeded()

        let boxLayer = try #require(overlay.highlightedBoxLayers.first)
        let pop = try #require(boxLayer.animation(forKey: PDFSearchHighlightOverlayView.popAnimationKey) as? CABasicAnimation)
        #expect(pop.fromValue as? Double == PDFSearchHighlightOverlayView.popScale)
        #expect(pop.duration == PDFSearchHighlightOverlayView.popDuration)
    }

    @Test func unchangedHighlight_doesNotPopAgainOnRelayout() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        let overlay = try fixture.overlay(onPage: 0)
        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)
        overlay.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(300))

        overlay.setNeedsLayout()
        overlay.layoutIfNeeded()

        let boxLayer = try #require(overlay.highlightedBoxLayers.first)
        #expect(boxLayer.animation(forKey: PDFSearchHighlightOverlayView.popAnimationKey) == nil)
    }

    @Test func recreatedOverlayView_doesNotPopAgain() async throws {
        let fixture = try await OverlayFixture(pages: ["alpha one"])
        let overlay = try fixture.overlay(onPage: 0)
        fixture.provider.show(try fixture.matches("alpha"), highlightedIndex: 0, dims: true)
        overlay.layoutIfNeeded()

        let recreated = try fixture.overlay(onPage: 0)

        let boxLayer = try #require(recreated.highlightedBoxLayers.first)
        #expect(boxLayer.animation(forKey: PDFSearchHighlightOverlayView.popAnimationKey) == nil)
    }

    @Test func highlightOnPageWithoutOverlayView_popsWhenItsViewIsCreated() async throws {
        let pages = Array(repeating: "filler", count: 11) + ["alpha far"]
        let fixture = try await OverlayFixture(pages: pages)
        let matches = try fixture.matches("alpha")

        fixture.provider.show(matches, highlightedIndex: 0, dims: true)
        let overlay = try fixture.overlay(onPage: pages.count - 1)

        let boxLayer = try #require(overlay.highlightedBoxLayers.first)
        #expect(boxLayer.animation(forKey: PDFSearchHighlightOverlayView.popAnimationKey) != nil)
    }
}

// MARK: - Helpers

@MainActor
private struct OverlayFixture {
    let base: SearchFixture
    let provider: PDFSearchHighlightOverlayProvider

    init(pages: [String], cropInset: CGFloat = 0) async throws {
        let provider = PDFSearchHighlightOverlayProvider()
        self.provider = provider
        base = try await SearchFixture(pages: pages, overlayProvider: provider)
        if cropInset > 0, let document = base.pdfView.document {
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { continue }
                let media = page.bounds(for: .mediaBox)
                page.setBounds(media.insetBy(dx: cropInset, dy: cropInset), for: .cropBox)
            }
            base.pdfView.layoutDocumentView()
            base.pdfView.layoutIfNeeded()
        }
    }

    func matches(_ query: String) throws -> [PDFSearchMatch] {
        let document = try #require(base.pdfView.document)
        return document.findString(query, withOptions: []).map {
            PDFSearchMatch(selection: $0, pageIndex: document.index(for: $0.pages[0]))
        }
    }

    /// Asks the provider for `pageIndex`'s overlay view, as PDFKit does, and
    /// lays it out at the page's aspect ratio.
    func overlay(onPage pageIndex: Int) throws -> PDFSearchHighlightOverlayView {
        let page = try #require(base.pdfView.document?.page(at: pageIndex))
        let view = try #require(
            provider.pdfView(base.pdfView, overlayViewFor: page) as? PDFSearchHighlightOverlayView
        )
        let box = page.bounds(for: base.pdfView.displayBox)
        view.frame = CGRect(x: 0, y: 0, width: 300, height: 300 * box.height / box.width)
        view.layoutIfNeeded()
        return view
    }
}

private struct RGB {
    let r: CGFloat, g: CGFloat, b: CGFloat

    func isClose(to colour: UIColor) -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return abs(r - red) < 0.05 && abs(g - green) < 0.05 && abs(b - blue) < 0.05
    }
}

private func rgbPixels(of layer: CALayer) throws -> [RGB] {
    let contents = try #require(layer.contents)
    let image = contents as! CGImage
    let width = image.width, height = image.height
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    let context = try #require(CGContext(
        data: &bytes, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return stride(from: 0, to: bytes.count, by: 4).map {
        RGB(r: CGFloat(bytes[$0]) / 255, g: CGFloat(bytes[$0 + 1]) / 255, b: CGFloat(bytes[$0 + 2]) / 255)
    }
}

/// The colour at the box's top left, inside its padding, where no glyph is.
private func cornerColour(of layer: CALayer) throws -> RGB {
    let pixels = try rgbPixels(of: layer)
    let image = layer.contents as! CGImage
    return pixels[2 * image.width + 2]
}

/// The alpha the overlay's dimming draws at `point`, from 0 where nothing
/// dims the page.
@MainActor
private func dimAlpha(of view: UIView, at point: CGPoint) throws -> CGFloat {
    var bytes = [UInt8](repeating: 0, count: 4)
    let context = try #require(CGContext(
        data: &bytes, width: 1, height: 1, bitsPerComponent: 8,
        bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.translateBy(x: -point.x, y: -point.y)
    view.layer.render(in: context)
    return CGFloat(bytes[3]) / 255
}
