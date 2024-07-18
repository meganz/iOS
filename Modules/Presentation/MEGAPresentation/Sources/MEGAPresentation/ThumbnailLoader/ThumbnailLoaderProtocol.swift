import SwiftUI
import MEGADomain
import MEGASwift

public protocol ThumbnailLoaderProtocol {
    
    /// Load initial image for a node
    ///  - Parameters:
    ///   - node - the node to retrieve initial image
    ///   - type: thumbnail type to check
    ///   - placeholder: image resource to use as placeholder if item is not found
    ///  - Returns: cached image for type or placeholder
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining
    
    /// Load image for a node
    ///  - Parameters:
    ///   - node - the node to retrieve initial image
    ///   - type: thumbnail type to check
    ///  - Returns: Async sequence that will yield requested type. If type is `.preview` or `.original` it will yield until preview is returned
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining>
}

extension ThumbnailLoaderProtocol {
    /// Load image for a node
    ///  - Parameters:
    ///   - node - the node to retrieve initial image
    ///   - type: thumbnail type to check
    ///  - Returns: image container immediately  when type found
    public func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> (any ImageContaining)? {
        try await loadImage(for: node, type: type)
            .first(where: { $0.type == type.toImageType() })
    }
}
