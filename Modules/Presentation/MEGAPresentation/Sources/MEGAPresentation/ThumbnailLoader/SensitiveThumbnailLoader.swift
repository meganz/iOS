import MEGADomain
import MEGASwift
import SwiftUI

struct SensitiveThumbnailLoader: ThumbnailLoaderProtocol {
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    init(thumbnailLoader: some ThumbnailLoaderProtocol,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) {
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        let initialImage = thumbnailLoader
            .initialImage(for: node, type: type, placeholder: placeholder)
        
        return if !sensitiveNodeUseCase.isAccessible() {
            initialImage
        } else if node.isMarkedSensitive {
            initialImage
                .toSensitiveImageContaining(isSensitive: node.isMarkedSensitive)
        } else {
            ImageContainer(image: placeholder(), type: .placeholder)
        }
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        let imageAsyncSequence = try await thumbnailLoader.loadImage(for: node, type: type)
        guard sensitiveNodeUseCase.isAccessible() else {
            return imageAsyncSequence
        }
        let isSensitive = if node.isMarkedSensitive {
            true
        } else {
            try await sensitiveNodeUseCase.isInheritingSensitivity(node: node)
        }
        return imageAsyncSequence
            .map {
                $0.toSensitiveImageContaining(isSensitive: isSensitive)
            }
            .eraseToAnyAsyncSequence()
    }
}
