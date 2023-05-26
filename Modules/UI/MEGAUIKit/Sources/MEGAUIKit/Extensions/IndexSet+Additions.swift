import Foundation
import UIKit

public extension IndexSet {
    func indexPaths(withSection section: Int) -> [IndexPath] {
        map { IndexPath(item: $0, section: section) }
    }
}
