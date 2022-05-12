import Foundation

actor PhotoLibraryMapper {
    
    func buildPhotoLibrary(with nodes: [PhotoLibraryNodeProtocol]) -> PhotoLibrary {
        if let nodes = nodes as? [MEGANode] {
            MEGALogDebug("[Photo] Convert nodes to PhotoLibrary in PhotoLibraryMapper!")
            return nodes.toPhotoLibrary()
        } else if let nodes = nodes as? [NodeEntity] {
            MEGALogDebug("[Album] Convert nodes to PhotoLibrary in PhotoLibraryMapper!")
            return nodes.toPhotoLibrary()
        }
        
        return PhotoLibrary()
    }
}
