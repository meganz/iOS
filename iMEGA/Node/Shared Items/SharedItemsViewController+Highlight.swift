import MEGADomain
import UIKit

extension SharedItemsViewController {

    /// How a highlighted row should look.
    enum RowHighlightStyle {
        /// One-shot tint that fades back to the page background.
        case flash
        /// Stays tinted until `clearPersistentHighlight()` is called. Survives
        /// cell reuse via the `willDisplayCell` hook.
        case persistent
    }

    /// Scrolls the row matching `handle` into view and highlights it.
    ///
    /// If the currently selected tab's data has not loaded yet (e.g. the caller
    /// invokes this right after pushing the screen), the request is remembered
    /// and re-applied by `reloadUI` once the table finishes its next reload.
    ///
    /// - Parameter style: `.flash` (default) for a one-shot cue, or `.persistent`
    ///   to keep the row tinted until `clearPersistentHighlight()` is called.
    func scrollToAndHighlightNode(handle: HandleEntity, style: RowHighlightStyle = .flash) {
        nodeHandleToHighlight = handle
        highlightPersists = (style == .persistent)
        applyHighlight(animated: true)
    }

    /// Removes a persistent highlight previously set via `.persistent` style.
    func clearPersistentHighlight() {
        let handle = nodeHandleToHighlight
        nodeHandleToHighlight = 0
        highlightPersists = false
        guard handle != 0,
              let indexPath = indexPathForNode(handle: handle),
              let cell = tableView?.cellForRow(at: indexPath) as? SharedItemsTableViewCell else { return }
        cell.setPersistentHighlight(false)
    }

    @objc(applyHighlightAnimated:)
    func applyHighlight(animated: Bool) {
        guard nodeHandleToHighlight != 0,
              let indexPath = indexPathForNode(handle: nodeHandleToHighlight) else {
            // Either nothing is highlighted, or the tab's data isn't ready yet —
            // keep the request so the next reloadUI can retry.
            return
        }

        // Only scroll when the row isn't already on screen, so a reload that
        // re-applies a persistent highlight doesn't yank the user's scroll
        // position.
        let isVisible = tableView?.indexPathsForVisibleRows?.contains(indexPath) ?? false
        if !isVisible {
            tableView?.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }

        let persists = highlightPersists
        // Flash is one-shot: forget the handle so later reloads don't re-flash.
        // Persistent keeps the handle so `willDisplayCell` can re-tint on reuse.
        if !persists {
            nodeHandleToHighlight = 0
        }

        // Animated scrolls take ~0.3s; defer grabbing the destination cell until
        // the scroll settles. If it's already visible (or non-animated), no wait.
        let delay: TimeInterval = (!isVisible && animated) ? 0.3 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let cell = self?.tableView?.cellForRow(at: indexPath) as? SharedItemsTableViewCell else { return }
            if persists {
                cell.setPersistentHighlight(true)
            } else {
                cell.flashHighlight()
            }
        }
    }

    /// Re-applies the persistent highlight when a cell is (re)displayed, so it
    /// survives scrolling. Called from `willDisplayCell`.
    @objc(configureHighlightForCell:handle:)
    func configureHighlight(for cell: SharedItemsTableViewCell, handle: HandleEntity) {
        cell.setPersistentHighlight(highlightPersists && nodeHandleToHighlight != 0 && handle == nodeHandleToHighlight)
    }

    private func indexPathForNode(handle: HandleEntity) -> IndexPath? {
        if incomingButton?.isSelected == true {
            firstIndexPath(in: incomingNodesMutableArray as? [MEGANode], section: .content, handle: handle)
                ?? firstIndexPath(in: incomingUnverifiedNodesMutableArray as? [MEGANode], section: .unverified, handle: handle)
        } else if outgoingButton?.isSelected == true {
            firstIndexPath(in: outgoingNodesMutableArray as? [MEGANode], section: .content, handle: handle)
                ?? firstIndexPath(in: outgoingUnverifiedNodesMutableArray as? [MEGANode], section: .unverified, handle: handle)
        } else if linksButton?.isSelected == true {
            firstIndexPath(in: publicLinksArray as? [MEGANode], section: .content, handle: handle)
        } else {
            nil
        }
    }

    private func firstIndexPath(
        in nodes: [MEGANode]?,
        section: SharedItemsViewControllerSection,
        handle: HandleEntity
    ) -> IndexPath? {
        guard let row = nodes?.firstIndex(where: { $0.handle == handle }) else { return nil }
        return IndexPath(row: row, section: section.rawValue)
    }
}
