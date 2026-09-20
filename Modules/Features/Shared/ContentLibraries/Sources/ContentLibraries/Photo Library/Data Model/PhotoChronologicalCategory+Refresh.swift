import Foundation
import MEGASwift

extension PhotoChronologicalCategory {
    public static func ↻↻ (lhs: Self, rhs: Self) -> Bool {
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto != rhs.coverPhoto
    }
    
    public static func ↻↻⏿ (lhs: Self, rhs: Self) -> Bool {
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto != rhs.coverPhoto ||
        lhs.coverPhoto?.hasThumbnail != rhs.coverPhoto?.hasThumbnail ||
        lhs.coverPhoto?.hasPreview != rhs.coverPhoto?.hasPreview ||
        lhs.coverPhoto?.isFavourite != rhs.coverPhoto?.isFavourite ||
        lhs.coverPhoto?.isMarkedSensitive != rhs.coverPhoto?.isMarkedSensitive
    }
}

extension Array where Element: PhotoChronologicalCategory {
    func shouldRefresh(to categories: [Element], visiblePositions: [PhotoScrollPosition?: Bool] = [:]) -> Bool {
        guard count == categories.count else { return true }
        
        for zip in zip(self, categories) {
            if visiblePositions[zip.0.position] == true {
                if zip.0 ↻↻⏿ zip.1 {
                    return true
                }
            } else {
                if zip.0 ↻↻ zip.1 {
                    return true
                }
            }
        }
        
        return false
    }
}

extension Array where Element: PhotoDateSection {
    /// The cells among `preparedIndexPaths` whose content changed between the receiver and
    /// `sections`, ascending, for the caller to `reconfigureItems(at:)`. `nil` when the section
    /// *structure* moved (section count, title, date or per-section item count), which the caller
    /// answers with a full reload instead.
    ///
    /// `preparedIndexPaths` is the set to compare, and has to cover every cell that already
    /// exists: with prefetching on, a cell just off screen is built and configured before it
    /// appears and is not rebuilt when it does, so one left out scrolls in showing what it was
    /// prepared with. A collection view cannot be asked which cells exist, so the caller passes a
    /// superset — every index path laid out near the viewport — and an index path with no cell
    /// behind it costs one comparison and reconfigures nothing. Anything beyond it is built from
    /// the caller's updated data source, which is what bounds a refresh by the viewport rather
    /// than by the size of the account.
    ///
    /// Cells are keyed by index path, which is sound because the structural guards run first: both
    /// sides then hold the same sections in the same order with the same counts, so an index path
    /// names the same cell in each. A node-derived key does not — a splice can transiently leave
    /// one node in two slots, collapsing two cells onto one key.
    ///
    /// - Note: The `nil` → full-reload branch is an interim fallback: any structural change (e.g. a
    ///   Camera-Upload insert growing the top day bucket) reloads the whole grid and can jump the
    ///   scroll position. The reactive-updates work replaces it with an incremental applier.
    func changedItemIndexPaths(
        to sections: [Element], amongPrepared preparedIndexPaths: Set<IndexPath>
    ) -> [IndexPath]? {
        guard count == sections.count else { return nil }
        for (old, new) in zip(self, sections) {
            guard old.title == new.title,
                  old.categoryDate == new.categoryDate,
                  old.itemCount == new.itemCount else {
                return nil
            }
        }
        return preparedIndexPaths.filter { indexPath in
            guard indices.contains(indexPath.section),
                  let old = self[indexPath.section].node(at: indexPath.item),
                  let new = sections[indexPath.section].node(at: indexPath.item) else { return false }
            return old ↻↻⏿ new
        }
        .sorted()
    }
}

extension Array where Element: PhotoSection {
    func shouldRefresh(to categories: [Element], visiblePositions: [PhotoScrollPosition?: Bool] = [:]) -> Bool {
        guard count == categories.count else { return true }
        for zip in zip(self, categories) {
            guard zip.0.title == zip.1.title, zip.0.categoryDate == zip.1.categoryDate else {
                return true
            }
            
            if zip.0.contentList.shouldRefresh(to: zip.1.contentList, visiblePositions: visiblePositions) {
                return true
            }
        }
        
        return false
    }
}
