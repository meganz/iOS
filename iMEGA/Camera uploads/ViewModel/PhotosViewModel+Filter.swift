import ContentLibraries
import Foundation
import MEGADomain

extension PhotosViewModel {
    
    func filter(nodes: inout [NodeEntity], with type: PhotosFilterOptions) {
        if type == .allMedia {
            nodes = nodes.filter { $0.hasThumbnail }
        } else if type == .images {
            nodes = nodes.filter { $0.fileExtensionGroup.isImage && $0.hasThumbnail }
        } else if type == .videos {
            nodes = nodes.filter { $0.fileExtensionGroup.isVideo && $0.hasThumbnail }
        }
    }
    
    @objc func hasNoPhotos() -> Bool {
        mediaNodes.isEmpty
    }
}
