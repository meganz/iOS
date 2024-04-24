import MEGADomain
import MEGAPresentation
import MEGASwift
import MEGASwiftUI
import SwiftUI

protocol ThumbnailLoaderProtocol {
    /// Load initial image for a node
    ///  - Parameters:
    ///   - node - the node to retrieve initial image
    ///   - type: thumbnail type to check
    ///  - Returns: cached image for type or placeholder for file type
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining
    
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
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> (any ImageContaining)? {
        try await loadImage(for: node, type: type)
            .first(where: { $0.type == type.toImageType() })
    }
}

struct ThumbnailLoader: ThumbnailLoaderProtocol {
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    init(thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        initialImage(for: node, type: type) {
            node.placeholderImage
        }
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        guard let container = thumbnailUseCase.cachedThumbnailContainer(for: node, type: type) else {
            return ImageContainer(image: placeholder(), type: .placeholder)
        }
        return container
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        switch type {
        case .thumbnail:
            if let cachedThumbnailContainer = thumbnailUseCase.cachedThumbnailContainer(for: node, type: .thumbnail) {
                return SingleItemAsyncSequence(item: cachedThumbnailContainer)
                    .eraseToAnyAsyncSequence()
            }
            let container = try await thumbnailUseCase.loadThumbnailContainer(for: node, type: .thumbnail)
            return SingleItemAsyncSequence(item: container)
                .eraseToAnyAsyncSequence()
        case .preview, .original:
            return if let container = thumbnailUseCase.cachedThumbnailContainer(for: node, type: type) {
                SingleItemAsyncSequence(item: container)
                    .eraseToAnyAsyncSequence()
            } else {
                thumbnailUseCase
                    .requestPreview(for: node)
                    .compactMap {
                        $0.toURLImageContainer()
                    }
                    .eraseToAnyAsyncSequence()
            }
        }
    }
}

extension NodeEntity {
    var placeholderImage: Image {
        Image(FileTypes().fileTypeResource(forFileName: name))
    }
}
