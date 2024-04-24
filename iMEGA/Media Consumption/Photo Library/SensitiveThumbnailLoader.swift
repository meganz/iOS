import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

struct SensitiveThumbnailLoader: ThumbnailLoaderProtocol {
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let nodeUseCaseProtocol: any NodeUseCaseProtocol
    
    init(thumbnailLoader: some ThumbnailLoaderProtocol,
         nodeUseCaseProtocol: some NodeUseCaseProtocol) {
        self.thumbnailLoader = thumbnailLoader
        self.nodeUseCaseProtocol = nodeUseCaseProtocol
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        initialImage(for: node, type: type) {
            node.placeholderImage
        }
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        if node.isMarkedSensitive {
            thumbnailLoader.initialImage(for: node, type: type)
                .toSensitiveImageContaining(isSensitive: node.isMarkedSensitive)
        } else {
            ImageContainer(image: placeholder(), type: .placeholder)
        }
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        let isSensitive = if node.isMarkedSensitive {
            true
        } else {
            try await nodeUseCaseProtocol.isInheritingSensitivity(node: node)
        }
        return try await thumbnailLoader.loadImage(for: node, type: type)
            .map {
                $0.toSensitiveImageContaining(isSensitive: isSensitive)
            }
            .eraseToAnyAsyncSequence()
    }
}

private extension ImageContaining {
    func toSensitiveImageContaining(isSensitive: Bool) -> some SensitiveImageContaining {
        SensitiveImageContainer(image: image,
                                type: type,
                                isSensitive: isSensitive)
    }
}
