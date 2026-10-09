import UIKit

/// Scrolls the list while a selection drag holds the finger near its top or bottom edge.
/// The speed grows with the depth in the edge zone (`SelectionGeometry.autoscrollSpeed`).
@MainActor
package final class SelectionAutoScroller: NSObject {
    private weak var scrollView: UIScrollView?
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var fingerInWindow: CGPoint?
    /// Called after each scroll step, after the layout pass, so the head can follow the content under the finger.
    package var onScroll: (() -> Void)?

    package init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()
    }

    package var isScrolling: Bool { link != nil }

    /// The finger moved. Starts or stops the scrolling.
    package func update(fingerInWindow point: CGPoint) {
        fingerInWindow = point
        if speed() == 0 {
            stop()
        } else if link == nil {
            let link = CADisplayLink(target: self, selector: #selector(step(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
            lastTimestamp = nil
        }
    }

    package func stop() {
        link?.invalidate()
        link = nil
        fingerInWindow = nil
    }

    private func speed() -> CGFloat {
        guard let scrollView, let fingerInWindow else { return 0 }
        let finger = scrollView.convert(fingerInWindow, from: nil)
        let inset = scrollView.adjustedContentInset
        let top = scrollView.contentOffset.y + inset.top
        let bottom = scrollView.contentOffset.y + scrollView.bounds.height - inset.bottom
        return SelectionGeometry.autoscrollSpeed(fingerY: finger.y, visibleTop: top, visibleBottom: bottom)
    }

    @objc private func step(_ link: CADisplayLink) {
        // A late frame moves at most 50 ms worth, so a stall does not throw the list far.
        let elapsed = min(lastTimestamp.map { link.timestamp - $0 } ?? link.duration, 0.05)
        lastTimestamp = link.timestamp
        guard let scrollView else {
            stop()
            return
        }
        let speed = speed()
        guard speed != 0 else {
            stop()
            return
        }
        let inset = scrollView.adjustedContentInset
        let minY = -inset.top
        let maxY = max(minY, scrollView.contentSize.height + inset.bottom - scrollView.bounds.height)
        let target = min(max(scrollView.contentOffset.y + speed * elapsed, minY), maxY)
        guard abs(target - scrollView.contentOffset.y) > 0.01 else { return }
        scrollView.contentOffset.y = target
        scrollView.layoutIfNeeded()
        onScroll?()
    }
}
