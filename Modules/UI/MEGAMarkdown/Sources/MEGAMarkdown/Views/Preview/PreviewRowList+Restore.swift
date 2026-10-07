import MEGAFoundation
import QuartzCore
import UIKit

// MARK: - Restore and top-line report

/// The restore line waits until its row is parsed, then the list jumps there and keeps that row at the top for 1 s.
/// A drag or a status bar tap ends the restore. A jump never starts while the user drags or the list decelerates.
/// While a restore waits, nothing is reported, so a host that saves every report does not save line 0 by mistake.
/// Both run in layout passes, never inside a SwiftUI update.
extension PreviewRowList.Coordinator {
    /// How long a jump target stays at the top while the rows around it size themselves.
    static let pinDuration: CFTimeInterval = 1

    /// Turns a waiting restore line into a jump once its row is known: a later row exists, or the text is complete.
    func resolveRestore() {
        guard let line = pendingRestoreLine, showsCurrentText else { return }
        if !isComplete {
            guard let last = store.last, last.sourceLine > line else { return }
        }
        pendingRestoreLine = nil
        guard let row = store.rowIndex(containing: line) else { return }
        if let last = store.last, line > last.sourceLine {
            MEGALog.log(
                level: .debug,
                message: "[PreviewRowList] Restore line is after the last row, showing the last row. line=\(line) lastRowLine=\(last.sourceLine)"
            )
        }
        pendingJump = row
    }

    /// The user takes over: no jump and no pin any more.
    func endRestore() {
        pendingRestoreLine = nil
        pendingJump = nil
        pin = nil
        needsReport = true
    }

    /// Runs after each layout pass of the list.
    func didLayout() {
        guard !isStopped else { return }
        // The window safe area of the list is known only in a layout pass.
        updateInsets()
        let view = list.view
        // A jump now would move the list under the finger and end the bounce at the edge.
        if view.isDragging || view.isDecelerating { pendingJump = nil }
        if let row = pendingJump, view.bounds.height > 0 {
            pendingJump = nil
            if row < list.itemCount {
                setOffset(jumpOffset(to: row).offset)
                pin = (row, CACurrentMediaTime() + Self.pinDuration)
            }
            needsReport = true
        } else if let pin {
            if CACurrentMediaTime() > pin.until || view.isDragging || view.isDecelerating || pin.row >= list.itemCount {
                self.pin = nil
            } else {
                setOffset(jumpOffset(to: pin.row).offset)
            }
        }
        if needsReport {
            needsReport = false
            reportTopLine()
        }
    }

    /// Reports the source line of the top row when it changed.
    private func reportTopLine() {
        guard pendingRestoreLine == nil, pendingJump == nil, list.itemCount > 0, let onTopLineChange else { return }
        // A pinned target is the top row, even while rows around it still size themselves.
        // A target the list cannot scroll to (near the end) is not at the top, so the real top row is reported.
        let pinned = pin.flatMap { jumpOffset(to: $0.row).isReachable ? $0.row : nil }
        let row = min(pinned ?? list.topItem, store.count - 1)
        let line = store[row].sourceLine
        guard line != reportedLine else { return }
        reportedLine = line
        onTopLineChange(line)
    }

    /// The offset that puts `row` at the top, kept inside the content. Not reachable when the rows below it are too short.
    func jumpOffset(to row: Int) -> (offset: CGFloat, isReachable: Bool) {
        let view = list.view
        let inset = view.adjustedContentInset
        let total = list.itemFrame(at: list.itemCount - 1).maxY
        let maxOffset = max(total + inset.bottom - view.bounds.height, -inset.top)
        let target = list.itemFrame(at: row).minY - inset.top
        return (min(target, maxOffset), target <= maxOffset + 0.5)
    }

    private func setOffset(_ y: CGFloat) {
        if abs(list.view.contentOffset.y - y) > 0.5 { list.view.contentOffset.y = y }
    }
}
