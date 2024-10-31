import Foundation
import MEGADomain

actor PhotoLibraryMapper {
    func buildPhotoLibrary(with nodes: [NodeEntity], withSortType type: SortOrderEntity) -> PhotoLibrary {
        nodes.toPhotoLibrary(withSortType: type)
    }
}
