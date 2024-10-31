import MEGADomain
import Foundation
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
}
