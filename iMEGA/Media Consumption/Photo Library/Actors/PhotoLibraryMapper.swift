import Foundation

actor PhotoLibraryMapper {
    func buildPhotoLibrary(with nodes: [PhotoLibraryNodeProtocol], withSortType type: SortOrderType) -> PhotoLibrary {
        if let nodes = nodes as? [MEGANode] {
            return nodes.toPhotoLibrary(withSortType: type)
        } else if let nodes = nodes as? [NodeEntity] {
            return nodes.toPhotoLibrary(withSortType: type)
        }
        
        return PhotoLibrary()
    }
}
