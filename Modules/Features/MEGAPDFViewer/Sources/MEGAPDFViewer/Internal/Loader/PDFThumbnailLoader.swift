import PDFKit
import UIKit

@MainActor
protocol PDFThumbnailLoading: AnyObject {
    func thumbnail(
        forPageAt pageIndex: Int,
        size: CGSize,
        displayScale: CGFloat
    ) async -> UIImage?
}

@MainActor
final class PDFThumbnailLoader: PDFThumbnailLoading {
    private struct ThumbnailKey: Hashable {
        let pageIndex: Int
        let pixelWidth: Int
        let pixelHeight: Int

        func asNSCacheKey() -> NSString {
            "\(pageIndex)-\(pixelWidth)x\(pixelHeight)" as NSString
        }
    }

    private let document: PDFDocument
    /// Bounded by decoded bytes rather than entry count, because one thumbnail
    /// ranges from 0.7 MB on an iPhone in portrait to 3.8 MB in landscape, so
    /// a page count is not a memory budget. 120 MB covers three screenfuls on
    /// every current device, the largest being 99.5 MB on an iPhone 17 in
    /// landscape.
    private let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 120 * 1024 * 1024
        return cache
    }()

    init(document: PDFDocument) {
        self.document = document
    }

    func thumbnail(
        forPageAt pageIndex: Int,
        size: CGSize,
        displayScale: CGFloat
    ) async -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let pixelSize = CGSize(
            width: size.width * displayScale,
            height: size.height * displayScale
        )
        let key = ThumbnailKey(
            pageIndex: pageIndex,
            pixelWidth: Int(pixelSize.width),
            pixelHeight: Int(pixelSize.height)
        )
        if let thumbnail = thumbnailCache.object(forKey: key.asNSCacheKey()) {
            return thumbnail
        }

        guard let page = document.page(at: pageIndex) else { return nil }
        let sendablePage = UncheckedSendablePDFPage(page: page)
        guard let thumbnail = await Self.render(
            page: sendablePage, pixelSize: pixelSize
        ) else { return nil }

        thumbnailCache.setObject(
            thumbnail,
            forKey: key.asNSCacheKey(),
            cost: thumbnail.decodedByteCount
        )
        return Task.isCancelled ? nil : thumbnail
    }

    /// Runs on the global concurrent executor rather than the caller's actor,
    /// so the draw never occupies the main thread.
    ///
    /// - The render stays inside the caller's task, so a caller that goes away
    ///   cancels it, and a render still queued exits at the check below rather
    ///   than drawing a thumbnail nobody will show.
    /// - `PDFPage.thumbnail` serialises per page rather than per document, so
    ///   concurrent renders of distinct pages do not contend.
    @concurrent
    private nonisolated static func render(
        page: UncheckedSendablePDFPage,
        pixelSize: CGSize
    ) async -> UIImage? {
        guard !Task.isCancelled else { return nil }
        return page.page.thumbnail(of: pixelSize, for: .cropBox)
    }
}

// `PDFPage` is not Sendable. Its only off-main use is the thumbnail renderer.
private struct UncheckedSendablePDFPage: @unchecked Sendable {
    let page: PDFPage
}

private extension UIImage {
    var decodedByteCount: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
