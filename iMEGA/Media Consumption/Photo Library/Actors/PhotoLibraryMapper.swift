import Foundation

actor PhotoLibraryMapper {
    func buildPhotoLibrary(with nodes: [MEGANode]) -> PhotoLibrary {
        MEGALogDebug("[Photos] Convert nodes to PhotoLibrary in PhotoLibraryMapper!")
        
        return nodes.toPhotoLibrary()
    }
}
