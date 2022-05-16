import Foundation

actor PhotoLibraryMapper {
    func buildPhotoLibrary(with nodes: [PhotoLibraryNodeProtocol]) -> PhotoLibrary {
        if let nodes = nodes as? [MEGANode] {
            return nodes.toPhotoLibrary()
        } else if let nodes = nodes as? [NodeEntity] {
            return nodes.toPhotoLibrary()
        }
        
        return PhotoLibrary()
    }
}
