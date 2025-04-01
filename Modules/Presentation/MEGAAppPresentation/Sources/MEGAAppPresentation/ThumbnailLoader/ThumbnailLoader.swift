import MEGADomain
import MEGASwift
import SwiftUI

struct ThumbnailLoader: ThumbnailLoaderProtocol {
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    init(thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.thumbnailUseCase = thumbnailUseCase
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
