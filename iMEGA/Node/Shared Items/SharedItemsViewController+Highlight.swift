import MEGADomain
import UIKit

extension SharedItemsViewController {

    /// Scrolls the row matching `handle` into view and flashes it once.
    ///
    /// If the currently selected tab's data has not loaded yet (e.g. the caller
    /// invokes this right after pushing the screen), the request is remembered
    /// and re-applied by `reloadUI` once the table finishes its next reload.
    func scrollToAndHighlightNode(handle: HandleEntity) {
        nodeHandleToHighlight = handle
        applyHighlight(animated: true)
    }

    @objc(applyHighlightAnimated:)
    func applyHighlight(animated: Bool) {
        guard nodeHandleToHighlight != 0,
              let indexPath = indexPathForNode(handle: nodeHandleToHighlight),
              let tableView,
              indexPath.section < tableView.numberOfSections,
              indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
            // Either nothing is highlighted, or the table hasn't reloaded this
            // tab's data yet — the model arrays can be populated before
            // `reloadData` runs (e.g. right after pushing the screen), so the
            // index path would be out of bounds. Keep the request so the next
            // reloadUI can retry once the table is in sync.
            return
        }

        // The flash is one-shot: forget the handle so later reloads don't re-flash.
        nodeHandleToHighlight = 0

        // Only scroll when the row isn't already on screen.
        let isVisible = tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false
        if !isVisible {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }

        // Animated scrolls take ~0.3s; defer grabbing the destination cell until
        // the scroll settles. If it's already visible (or non-animated), no wait.
        let delay: TimeInterval = (!isVisible && animated) ? 0.3 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let cell = self?.tableView?.cellForRow(at: indexPath) as? SharedItemsTableViewCell else { return }
            cell.flashHighlight()
        }
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
