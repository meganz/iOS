import PDFKit
import UIKit

/// Draws search matches in PDFKit's per-page overlay views, in the look of
/// UIKit's Find: dimmed pages, undimmed rounded boxes for matches, and the
/// highlighted match in yellow with a short pop.
@MainActor
final class PDFSearchHighlightOverlayProvider: NSObject {
    private var highlightsByPage: [ObjectIdentifier: [PDFSearchHighlightOverlayView.Highlight]] = [:]
    private var overlayViews: [ObjectIdentifier: PDFSearchHighlightOverlayView] = [:]
    private var pageByMatch: [ObjectIdentifier] = []
    private var highlightedIndex: Int?
    private var dims = false
    private var highlightPopIsPending = false

    /// Shows `matches`, with `highlightedIndex` in the highlighted colour, on
    /// pages dimmed when `dims` is true.
    /// - A list shorter than the shown one replaces it; any other list is
    ///   taken to extend it, and only its new matches are drawn.
    func show(_ matches: [PDFSearchMatch], highlightedIndex: Int?, dims: Bool) {
        var touchedPages = removeHighlights(replacedBy: matches)
        touchedPages.formUnion(appendHighlights(of: matches))
        touchedPages.formUnion(moveHighlight(to: highlightedIndex))
        if dims != self.dims {
            self.dims = dims
            // Every shown page dims or undims, not only pages with matches.
            touchedPages.formUnion(overlayViews.keys)
        }
        for key in touchedPages {
            guard let overlay = overlayViews[key] else { continue }
            overlay.update(
                highlightsByPage[key] ?? [],
                highlightedIndex: highlightedIndex,
                dims: dims,
                popsHighlighted: takePendingPop(forPage: key)
            )
        }
    }

    /// Returns the pages that lost their highlights.
    private func removeHighlights(replacedBy matches: [PDFSearchMatch]) -> Set<ObjectIdentifier> {
        guard matches.count < pageByMatch.count else { return [] }
        let touchedPages = Set(highlightsByPage.keys)
        highlightsByPage = [:]
        pageByMatch = []
        return touchedPages
    }

    /// Returns the pages that gained highlights.
    private func appendHighlights(of matches: [PDFSearchMatch]) -> Set<ObjectIdentifier> {
        var touchedPages = Set<ObjectIdentifier>()
        for matchIndex in pageByMatch.count..<matches.count {
            let selection = matches[matchIndex].selection
            // One rect per line, so a match that wraps covers only its own
            // text on its first and last lines, not their full width.
            for line in selection.selectionsByLine() {
                for page in line.pages {
                    let key = ObjectIdentifier(page)
                    highlightsByPage[key, default: []].append(
                        .init(rect: line.bounds(for: page), matchIndex: matchIndex)
                    )
                    touchedPages.insert(key)
                }
            }
            pageByMatch.append(selection.pages.first.map(ObjectIdentifier.init) ?? ObjectIdentifier(self))
        }
        return touchedPages
    }

    /// Returns the pages of the previously and newly highlighted matches.
    private func moveHighlight(to highlightedIndex: Int?) -> Set<ObjectIdentifier> {
        guard highlightedIndex != self.highlightedIndex else { return [] }
        let touchedPages = [self.highlightedIndex, highlightedIndex]
            .compactMap { $0 }
            .filter { $0 < pageByMatch.count }
            .map { pageByMatch[$0] }
        self.highlightedIndex = highlightedIndex
        highlightPopIsPending = highlightedIndex != nil
        return Set(touchedPages)
    }

    /// Returns true once per highlight change, for the page of the highlighted
    /// match.
    /// - The page may have no overlay view until the jump to the match
    ///   scrolls it into view, so the pop waits for the next view of that
    ///   page rather than being dropped.
    private func takePendingPop(forPage key: ObjectIdentifier) -> Bool {
        guard highlightPopIsPending,
              let highlightedIndex,
              highlightedIndex < pageByMatch.count,
              pageByMatch[highlightedIndex] == key
        else { return false }
        highlightPopIsPending = false
        return true
    }
}

// MARK: - PDFPageOverlayViewProvider

extension PDFSearchHighlightOverlayProvider: @preconcurrency PDFPageOverlayViewProvider {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        // PDFKit recreates a page's overlay view whenever the page scrolls
        // back into view, so it starts from the stored highlights.
        let overlay = PDFSearchHighlightOverlayView(page: page, displayBox: view.displayBox)
        overlay.update(
            highlightsByPage[ObjectIdentifier(page)] ?? [],
            highlightedIndex: highlightedIndex,
            dims: dims,
            popsHighlighted: takePendingPop(forPage: ObjectIdentifier(page))
        )
        overlayViews[ObjectIdentifier(page)] = overlay
        return overlay
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        let key = ObjectIdentifier(page)
        if overlayViews[key] === overlayView {
            overlayViews[key] = nil
        }
    }
}

/// One page's overlay: a dimming layer while a search has matches, and a
/// box per line of each match on the page.
final class PDFSearchHighlightOverlayView: UIView {
    struct Box {
        let matchIndex: Int
        let isHighlighted: Bool
        let frame: CGRect
    }

    struct Highlight {
        let rect: CGRect
        let matchIndex: Int
    }

    // Sampled from UIKit's Find decoration on iOS 26.5.
    static let dimColor = UIColor.black.withAlphaComponent(0.21)
    static let highlightedColor = UIColor(red: 251 / 255, green: 252 / 255, blue: 0, alpha: 1)
    static let padding = CGSize(width: 3.5, height: 2.5)
    static let popScale = 1.19
    static let popDuration = 0.15
    static let popAnimationKey = "pop"
    static let dimDuration = 0.15

    var isDimmed: Bool { !dimLayer.isHidden }
    private(set) var boxes: [Box] = []
    /// The highlighted match's boxes, one per line, drawn over the page with
    /// its glyphs.
    private(set) var highlightedBoxLayers: [CALayer] = []
    /// How many times the provider has changed what this view shows.
    private(set) var updateCount = 0

    private weak var page: PDFPage?
    private let displayBox: PDFDisplayBox
    private let dimLayer = CALayer()
    private let dimMask = CAShapeLayer()
    private var highlights: [Highlight] = []
    private var highlightedIndex: Int?
    private var popsHighlightedOnLayout = false

    init(page: PDFPage, displayBox: PDFDisplayBox) {
        self.page = page
        self.displayBox = displayBox
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        dimLayer.backgroundColor = Self.dimColor.cgColor
        dimLayer.isHidden = true
        dimLayer.mask = dimMask
        layer.addSublayer(dimLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows `highlights`, and pops the highlighted match's box at the next
    /// layout when `popsHighlighted` is true.
    func update(_ highlights: [Highlight], highlightedIndex: Int?, dims: Bool, popsHighlighted: Bool) {
        self.highlights = highlights
        self.highlightedIndex = highlightedIndex
        if popsHighlighted {
            popsHighlightedOnLayout = true
        }
        CATransaction.begin()
        // A view PDFKit has just created starts in its final state rather
        // than fading in as its page scrolls into view.
        CATransaction.setDisableActions(window == nil)
        CATransaction.setAnimationDuration(Self.dimDuration)
        dimLayer.isHidden = !dims
        CATransaction.commit()
        updateCount += 1
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        highlightedBoxLayers.forEach { $0.removeFromSuperlayer() }
        highlightedBoxLayers = []
        boxes = []
        guard let page else { return }
        let box = page.bounds(for: displayBox)
        guard box.width > 0, box.height > 0, bounds.width > 0 else { return }
        let scale = CGSize(width: bounds.width / box.width, height: bounds.height / box.height)
        let pixelsPerPoint = scale.width * (window?.screen.scale ?? traitCollection.displayScale)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dimLayer.frame = bounds
        dimMask.frame = bounds
        // Found matches are holes in the dimming, so PDFKit's own drawing of
        // the page shows through them undimmed.
        let holes = CGMutablePath()
        for highlight in highlights {
            let padded = highlight.rect.insetBy(dx: -Self.padding.width, dy: -Self.padding.height)
            // Page space has its origin at the bottom left of the box.
            let frame = CGRect(
                x: (padded.minX - box.minX) * scale.width,
                y: (box.maxY - padded.maxY) * scale.height,
                width: padded.width * scale.width,
                height: padded.height * scale.height
            )
            let isHighlighted = highlight.matchIndex == highlightedIndex
            boxes.append(Box(matchIndex: highlight.matchIndex, isHighlighted: isHighlighted, frame: frame))
            if isHighlighted {
                addHighlightedBox(at: frame, showing: padded, of: page, pixelsPerPoint: pixelsPerPoint)
            } else {
                holes.addPath(UIBezierPath(roundedRect: frame, cornerRadius: Self.cornerRadius(of: frame)).cgPath)
            }
        }
        dimMask.path = CGPath(rect: bounds, transform: nil).subtracting(holes)
        popsHighlightedOnLayout = false
        CATransaction.commit()
    }

    private func addHighlightedBox(
        at frame: CGRect,
        showing pageRect: CGRect,
        of page: PDFPage,
        pixelsPerPoint: CGFloat
    ) {
        let boxLayer = CALayer()
        boxLayer.frame = frame
        boxLayer.cornerRadius = Self.cornerRadius(of: frame)
        boxLayer.masksToBounds = true
        boxLayer.contents = Self.render(
            page,
            in: pageRect,
            box: displayBox,
            fill: Self.highlightedColor,
            pixelsPerPoint: pixelsPerPoint
        )?.cgImage
        layer.addSublayer(boxLayer)
        highlightedBoxLayers.append(boxLayer)
        if popsHighlightedOnLayout {
            let pop = CABasicAnimation(keyPath: "transform.scale")
            pop.fromValue = Self.popScale
            pop.toValue = 1.0
            pop.duration = Self.popDuration
            pop.timingFunction = CAMediaTimingFunction(name: .easeOut)
            boxLayer.add(pop, forKey: Self.popAnimationKey)
        }
    }

    private static func cornerRadius(of frame: CGRect) -> CGFloat {
        min(frame.height * 0.25, 6)
    }

    /// Draws the page's content inside `rect` over `fill`, so the glyphs stay
    /// legible on an opaque box.
    private static func render(
        _ page: PDFPage,
        in rect: CGRect,
        box: PDFDisplayBox,
        fill: UIColor,
        pixelsPerPoint: CGFloat
    ) -> UIImage? {
        let size = CGSize(width: ceil(rect.width * pixelsPerPoint), height: ceil(rect.height * pixelsPerPoint))
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(fill.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            // Multiply keeps dark glyphs dark and turns the page's white
            // background into the box colour.
            cgContext.setBlendMode(.multiply)
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: pixelsPerPoint, y: -pixelsPerPoint)
            cgContext.translateBy(x: -rect.minX, y: -rect.minY)
            // `rect` is in unrotated page space, while `draw(with:to:)`
            // applies the page's rotation and crop origin, so they are undone
            // first.
            cgContext.concatenate(page.transform(for: box).inverted())
            page.draw(with: box, to: cgContext)
        }
    }
}
