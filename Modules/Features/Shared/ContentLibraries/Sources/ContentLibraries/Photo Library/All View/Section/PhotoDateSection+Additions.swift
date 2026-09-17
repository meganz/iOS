import Foundation
import MEGADomain
import UIKit

extension Array where Element: PhotoDateSection {
    func photo(at indexPath: IndexPath) -> NodeEntity? {
        self[safe: indexPath.section]?.node(at: indexPath.item)
    }
    
    var allPhotos: [NodeEntity] {
        flatMap { $0.nodes }
    }
    
    var hydratedPhotos: [NodeEntity] {
        allPhotos.filter { !$0.isTimelinePlaceholder }
    }
    
    func indexPath(of position: PhotoScrollPosition, in timeZone: TimeZone? = nil) -> IndexPath? {
        for (sectionIndex, section) in self.enumerated() where section.photoByDayList.contains(where: { $0.categoryDate == position.date.removeTimestamp(timeZone: timeZone) }) {
            for (itemIndex, photo) in section.nodes.enumerated() where photo.handle == position.handle {
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
            
            break
        }
        
        return nil
    }
    
    /// Scroll position of an item, dated by the day bucket the item sits in rather than by the
    /// node's own timestamp — because ``indexPath(of:in:)`` resolves a position by matching that
    /// bucket date, and the two can disagree. On the paginated timeline the buckets come from
    /// the SDK's `groupId`s: they follow a fixed UTC offset, and when the timeline is ordered by
    /// media capture time they are cut on a different timestamp column than `modificationTime`
    /// altogether. Taking the date from the bucket keeps `position(at:) → indexPath(of:)` a
    /// round trip, so the grid returns to where the user left it.
    ///
    /// The Day / Month / Year cards reach the same date from the other side, through
    /// ``PhotoChronologicalCategory/coverDayDate``, so a card → grid jump resolves too.
    func position(at indexPath: IndexPath) -> PhotoScrollPosition? {
        guard let photo = photo(at: indexPath) else { return nil }
        guard let dayDate = dayCategoryDate(at: indexPath) else { return photo.position }
        return PhotoScrollPosition(handle: photo.handle, date: dayDate)
    }

    /// `categoryDate` of the day bucket holding the item at `indexPath`.
    private func dayCategoryDate(at indexPath: IndexPath) -> Date? {
        self[safe: indexPath.section]?.dayCategoryDate(at: indexPath.item)
    }

    /// Flat position of an index path within the flattened `allPhotos` order: the sum of all
    /// prior sections' item counts plus the item. Zoom-independent (grouping changes the
    /// section split but not the flat order). Returns nil for an out-of-bounds section.
    func flatIndex(of indexPath: IndexPath) -> Int? {
        guard indices.contains(indexPath.section) else { return nil }
        let itemsBeforeSection = self[..<indexPath.section].reduce(0) { $0 + $1.itemCount }
        return itemsBeforeSection + indexPath.item
    }
    
    func indexPaths(from start: IndexPath, to end: IndexPath) -> [IndexPath] {
        let isStartBeforeEnd = start.section < end.section || (start.section == end.section && start.item <= end.item)
        let (first, last) = isStartBeforeEnd ? (start, end) : (end, start)
        
        var indexPaths = [IndexPath]()
        for section in first.section...last.section {
            guard let itemCount = self[safe: section]?.itemCount else { continue }
            
            let startItem = (section == first.section) ? first.item : 0
            let endItem = (section == last.section) ? last.item : itemCount - 1
            
            guard startItem <= endItem else { continue }
            for item in startItem...endItem {
                indexPaths.append(IndexPath(item: item, section: section))
            }
        }
        return indexPaths
    }
}
