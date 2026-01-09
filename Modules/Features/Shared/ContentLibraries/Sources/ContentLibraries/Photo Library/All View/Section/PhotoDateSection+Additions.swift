import Foundation
import MEGADomain
import UIKit

extension Array where Element: PhotoDateSection {
    func photo(at indexPath: IndexPath) -> NodeEntity? {
        self[safe: indexPath.section]?.contentList[safe: indexPath.item]
    }
    
    var allPhotos: [NodeEntity] {
        flatMap { $0.contentList }
    }
    
    func indexPath(of position: PhotoScrollPosition, in timeZone: TimeZone? = nil) -> IndexPath? {
        for (sectionIndex, section) in self.enumerated() where section.photoByDayList.contains(where: { $0.categoryDate == position.date.removeTimestamp(timeZone: timeZone) }) {
            for (itemIndex, photo) in section.contentList.enumerated() where photo.handle == position.handle {
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
            
            break
        }
        
        return nil
    }
    
    func position(at indexPath: IndexPath) -> PhotoScrollPosition? {
        photo(at: indexPath)?.position
    }
    
    func indexPaths(from start: IndexPath, to end: IndexPath) -> [IndexPath] {
        let isStartBeforeEnd = start.section < end.section || (start.section == end.section && start.item <= end.item)
        let (first, last) = isStartBeforeEnd ? (start, end) : (end, start)
        
        var indexPaths = [IndexPath]()
        for section in first.section...last.section {
            guard let sectionContent = self[safe: section]?.contentList else { continue }
            
            let startItem = (section == first.section) ? first.item : 0
            let endItem = (section == last.section) ? last.item : sectionContent.count - 1
            
            guard startItem <= endItem else { continue }
            for item in startItem...endItem {
                indexPaths.append(IndexPath(item: item, section: section))
            }
        }
        return indexPaths
    }
}
