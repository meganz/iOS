import Foundation
@testable import MEGAPDFViewer
import Testing

struct PDFSearchVisibleRectTests {
    @Test func hitBehindTopChrome_expandsToVisibleBand() {
        let rect = PDFSearchVisibleRect.rect(
            for: CGRect(x: 0, y: 20, width: 40, height: 20),
            in: CGRect(x: 0, y: 0, width: 320, height: 700),
            obstructions: [CGRect(x: 0, y: 0, width: 320, height: 100)]
        )

        #expect(rect == CGRect(x: 0, y: -80, width: 40, height: 120))
    }

    @Test func clearBandHit_doesNotNeedCorrection() {
        let rect = PDFSearchVisibleRect.rect(
            for: CGRect(x: 0, y: 200, width: 40, height: 20),
            in: CGRect(x: 0, y: 0, width: 320, height: 700),
            obstructions: []
        )

        #expect(rect == CGRect(x: 0, y: 200, width: 40, height: 20))
    }

    @Test func hitWithinBand_ignoresTopAndBottomObstructions() {
        let hit = CGRect(x: 0, y: 200, width: 40, height: 20)
        let rect = PDFSearchVisibleRect.rect(
            for: hit,
            in: CGRect(x: 0, y: 0, width: 320, height: 700),
            obstructions: [
                CGRect(x: 0, y: 0, width: 320, height: 100),
                CGRect(x: 0, y: 500, width: 320, height: 200)
            ]
        )

        #expect(rect == hit)
    }

    @Test func hitBehindKeyboard_expandsToVisibleBand() {
        let rect = PDFSearchVisibleRect.rect(
            for: CGRect(x: 0, y: 620, width: 40, height: 20),
            in: CGRect(x: 0, y: 0, width: 320, height: 700),
            obstructions: [CGRect(x: 0, y: 500, width: 320, height: 200)]
        )

        #expect(rect == CGRect(x: 0, y: 620, width: 40, height: 220))
    }

    @Test func hitBehindKeyboard_viewportEndsPastKeyboard_expandsToVisibleBand() throws {
        // `UIView.convert(_:to:)` can return a viewport ending at
        // 700.0000000000002 while the keyboard ends at 700.
        let viewport = CGRect(x: 0, y: 0, width: 320, height: 700.0000000000002)
        let rect = PDFSearchVisibleRect.rect(
            for: CGRect(x: 0, y: 620, width: 40, height: 20),
            in: viewport,
            obstructions: [CGRect(x: 0, y: 500, width: 320, height: 200)]
        )

        let height = try #require(rect?.height)
        #expect(abs(height - 220) < 0.001)
    }
}
