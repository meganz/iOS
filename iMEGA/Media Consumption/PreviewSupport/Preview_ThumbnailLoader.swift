import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

struct Preview_ThumbnailLoader: ThumbnailLoaderProtocol {
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        ImageContainer(image: Image("folder"), type: .thumbnail)
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        ImageContainer(image: Image("folder"), type: .thumbnail)
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
