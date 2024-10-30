import MEGAAssets
import MEGADomain
import MEGAPresentation
import SwiftUI

extension ThumbnailLoaderProtocol {
    /// Load initial image for a node
    ///  - Parameters:
    ///   - node - the node to retrieve initial image
    ///   - type: thumbnail type to check
    ///  - Returns: cached image for type or placeholder for file type
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        initialImage(for: node, type: type) {
            node.placeholderImage
        }
    }
}

fileprivate extension NodeEntity {
    var placeholderImage: Image {
        MEGAAssetsImageProvider.fileTypeResource(forFileName: name)
    }
}
