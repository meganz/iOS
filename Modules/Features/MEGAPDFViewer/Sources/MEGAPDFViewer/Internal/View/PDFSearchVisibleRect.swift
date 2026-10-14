import Foundation

enum PDFSearchVisibleRect {
    static func rect(for hit: CGRect, in viewport: CGRect, obstructions: [CGRect]) -> CGRect? {
        guard !hit.isNull, !hit.isInfinite, !hit.isEmpty,
              !viewport.isNull, !viewport.isInfinite, !viewport.isEmpty else { return nil }

        var usableTop = viewport.minY
        var usableBottom = viewport.maxY
        for obstruction in obstructions where !obstruction.isNull && !obstruction.isInfinite
            && !obstruction.isEmpty && obstruction.intersects(viewport) {
            guard obstruction.minX < hit.maxX, obstruction.maxX > hit.minX else { continue }
            if obstruction.minY <= viewport.minY {
                usableTop = max(usableTop, min(obstruction.maxY, viewport.maxY))
            } else {
                // An obstruction starting inside the viewport hides what lies
                // below it, so it need not reach `viewport.maxY`, which
                // `UIView.convert(_:to:)` can overshoot by float noise.
                usableBottom = min(usableBottom, obstruction.minY)
            }
        }
        guard usableTop < usableBottom else { return nil }
        if hit.minY >= usableTop, hit.maxY <= usableBottom { return hit }

        return CGRect(
            x: hit.minX,
            y: hit.minY - (usableTop - viewport.minY),
            width: hit.width,
            height: hit.height + usableTop - viewport.minY + viewport.maxY - usableBottom
        )
    }
}
