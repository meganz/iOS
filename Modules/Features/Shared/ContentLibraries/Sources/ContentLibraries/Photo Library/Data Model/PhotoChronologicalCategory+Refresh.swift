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

extension Array where Element: PhotoSection {
    /// A precise refresh plan for moving from the receiver to `sections`, valid only while the
    /// section *structure* is unchanged (same section count, titles, dates and per-section item
    /// counts). Returns the item index paths whose content changed — so the caller can
    /// `reconfigureItems(at:)` exactly those cells in place instead of reloading the whole grid.
    /// Returns `nil` when the structure differs, signalling the caller to fall back to a full
    /// reload. Mirrors `shouldRefresh(to:visiblePositions:)`: thumbnail-aware comparison for
    /// on-screen items, the lighter comparison elsewhere.
    ///
    /// - Note: The `nil` → full-reload branch is an interim fallback — any structural change (e.g.
    ///   a Camera-Upload insert growing the top day bucket) reloads the whole grid and can jump the
    ///   scroll position. The reactive-updates work replaces it with an identity-keyed incremental
    ///   applier (`performBatchUpdates` + `contentOffset` preservation).
    func changedItemIndexPaths(to sections: [Element], visiblePositions: [PhotoScrollPosition?: Bool] = [:]) -> [IndexPath]? {
        guard count == sections.count else { return nil }
        var changed = [IndexPath]()
        for (sectionIndex, pair) in zip(self, sections).enumerated() {
            let (old, new) = pair
            guard old.title == new.title,
                  old.categoryDate == new.categoryDate,
                  old.contentList.count == new.contentList.count else {
                return nil
            }
            for (itemIndex, items) in zip(old.contentList, new.contentList).enumerated() {
                let didChange = visiblePositions[items.0.position] == true
                    ? items.0 ↻↻⏿ items.1
                    : items.0 ↻↻ items.1
                if didChange {
                    changed.append(IndexPath(item: itemIndex, section: sectionIndex))
                }
            }
        }
        return changed
    }
    
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
