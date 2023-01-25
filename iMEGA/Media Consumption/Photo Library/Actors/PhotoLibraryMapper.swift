import Foundation
import MEGADomain

actor PhotoLibraryMapper {
    func buildPhotoLibrary(with nodes: [NodeEntity], withSortType type: SortOrderType) -> PhotoLibrary {
        nodes.toPhotoLibrary(withSortType: type)
    }
}
