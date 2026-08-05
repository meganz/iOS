import Foundation

/// Select-mode selection for the Transfers list, shared between the screen and
/// the mounted tab.
///
/// The mounted tab's `TransferTabListViewModel` keeps `listedTags` in step with
/// the rows it lists; the screen reads `count` for the top-bar title and action
/// enablement, and calls `toggleSelectAll()` / `clear()`. Because the tab
/// container is re-keyed per tab, exactly one tab is listed at a time.
///
/// Every mutation is a plain `Set` assignment — no Combine operators anywhere in
/// this path — so a row tap, select-all and pruning all land in the same frame
/// as the event that caused them.
@MainActor
final class TransferSelection: ObservableObject {
    @Published var selectedTags: Set<Int> = []

    /// The tags the mounted tab currently lists. Not published: it feeds
    /// select-all and pruning, and nothing renders from it directly.
    private(set) var listedTags: Set<Int> = []

    var count: Int { selectedTags.count }

    var isEmpty: Bool { selectedTags.isEmpty }

    /// Select-all while any listed row is unselected; deselect-all once they all
    /// are. Pure `Set` work, so the row array is untouched and no list diff runs.
    ///
    /// The predicate is containment, not equality: a selected row can briefly
    /// outlive its entry in `listedTags`, and under equality that leftover would
    /// make every tap re-run select-all — a button that looks dead until the sets
    /// happen to line up again.
    func toggleSelectAll() {
        if listedTags.isSubset(of: selectedTags) {
            selectedTags = []
        } else {
            selectedTags = listedTags
        }
    }

    func clear() {
        guard !selectedTags.isEmpty else { return }
        selectedTags.removeAll()
    }

    func select(_ tag: Int) {
        guard !selectedTags.contains(tag) else { return }
        selectedTags.insert(tag)
    }

    /// Replaces the listed tags and drops any selection that left the list.
    /// Called on the paths that re-derive the whole list (snapshot, flush).
    func setListedTags(_ tags: Set<Int>) {
        listedTags = tags
        let surviving = selectedTags.intersection(tags)
        guard surviving != selectedTags else { return }
        selectedTags = surviving
    }

    /// Drops one tag in O(1). Used on the synchronous removal path so a selected
    /// row that just left the list stops counting immediately, without waiting
    /// for the throttled list flush.
    func dropListedTag(_ tag: Int) {
        listedTags.remove(tag)
        guard selectedTags.contains(tag) else { return }
        selectedTags.remove(tag)
    }
}
