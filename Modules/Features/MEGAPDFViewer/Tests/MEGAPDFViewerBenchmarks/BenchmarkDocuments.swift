import PDFKit
import UIKit

/// Test documents, generated so the benchmarks need no committed PDF corpus.
/// Each is written once per test process.
@MainActor
enum BenchmarkDocuments {
    static let pageCount = 96
    private static var scannedURL: URL?
    private static var textURL: URL?

    /// US Letter, the page size of every generated document.
    private static let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)

    /// Every page carries its own full-page 150 dpi JPEG, like a scanned
    /// document. The most expensive pages to thumbnail.
    static func makeScannedDocument() throws -> URL {
        if let scannedURL { return scannedURL }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MEGAPDFViewerBenchmarks-scanned.pdf")
        try UIGraphicsPDFRenderer(bounds: pageBounds).writePDF(to: url) { context in
            for index in 0..<pageCount {
                context.beginPage()
                scannedPageImage(seed: index).draw(in: pageBounds)
            }
        }
        scannedURL = url
        return url
    }

    /// Every page is a column of system-font text. The cheapest pages to
    /// thumbnail.
    static func makeTextDocument() throws -> URL {
        if let textURL { return textURL }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MEGAPDFViewerBenchmarks-text.pdf")
        let sentence = "The quick brown fox jumps over the lazy dog, then naps in the sun. "
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10)]
        try UIGraphicsPDFRenderer(bounds: pageBounds).writePDF(to: url) { context in
            for index in 0..<pageCount {
                context.beginPage()
                let text = "Page \(index + 1)\n\n" + String(repeating: sentence, count: 60)
                text.draw(in: pageBounds.insetBy(dx: 54, dy: 54), withAttributes: attributes)
            }
        }
        textURL = url
        return url
    }

    /// A grey page with dark text-like bars and per-pixel noise, so that no two
    /// pages share image data and the JPEG does not collapse to nothing.
    private static func scannedPageImage(seed: Int) -> UIImage {
        let width = 1_275
        let height = 1_650
        var pixels = [UInt8](repeating: 0, count: width * height)
        var state = UInt32(truncatingIfNeeded: seed &* 2_654_435_761 &+ 1)
        for y in 0..<height {
            let isTextRow = (y / 24).isMultiple(of: 2) && y > 150 && y < height - 150
            for x in 0..<width {
                state = state &* 1_664_525 &+ 1_013_904_223
                let noise = Int(state >> 28)
                let isInk = isTextRow && x > 120 && x < width - 120 && (x / 9 + y / 24 + seed) % 7 != 0
                pixels[y * width + x] = UInt8((isInk ? 40 : 230) + noise)
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ),
              let jpeg = UIImage(cgImage: image).jpegData(compressionQuality: 0.6),
              let scanned = UIImage(data: jpeg) else {
            return UIImage()
        }
        return scanned
    }
}

/// Grid geometry of `PDFThumbnailGridView` on an iPhone 17 (402 x 874 pt,
/// @3x): 3 columns, `TokenSpacing._3` (8 pt) between and around them, cells
/// at the design's 123.33:168 ratio.
enum ThumbnailGeometry {
    static let displayScale: CGFloat = 3
    static let portraitCell = cellSize(gridWidth: 402)
    static let landscapeCell = cellSize(gridWidth: 874)
    /// 3 x 4 cells fill a portrait screen, 3 x 3 a landscape one.
    static let portraitScreenful = 12
    static let landscapeScreenful = 9

    static func pixelSize(of cell: CGSize) -> CGSize {
        CGSize(width: cell.width * displayScale, height: cell.height * displayScale)
    }

    private static func cellSize(gridWidth: CGFloat) -> CGSize {
        let width = (gridWidth - 8 * 4) / 3
        return CGSize(width: width, height: width / (123.33 / 168))
    }
}
