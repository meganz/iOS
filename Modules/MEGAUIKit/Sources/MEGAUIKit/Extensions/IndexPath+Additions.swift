import Foundation
import UIKit

public extension IndexPath {
    var previousSectionIndexPath: IndexPath? {
        guard !isEmpty, section > 0 else { return nil }

        let previousIndexPath = IndexPath(item: item, section: section - 1)
        return previousIndexPath
    }
    
    func hasPrevious() -> Bool { row > 0 }

    func previous() -> IndexPath {
        return IndexPath(row: self.row - 1, section: self.section)
    }

    func next() -> IndexPath {
        return IndexPath(row: self.row + 1, section: self.section)
    }
}
