import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

public struct MockThumbnailLoader: ThumbnailLoaderProtocol {
    private let initialImage: any ImageContaining
    private let loadImage: AnyAsyncSequence<any ImageContaining>
    private let loadImages: [HandleEntity: AnyAsyncSequence<any ImageContaining>]
    
    public init(initialImage: any ImageContaining = ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder),
                loadImage: AnyAsyncSequence<any ImageContaining> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
                loadImages: [HandleEntity: AnyAsyncSequence<any ImageContaining>] = [:]) {
        self.initialImage = initialImage
        self.loadImage = loadImage
        self.loadImages = loadImages
    }
    
    public func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        initialImage
    }
    
    public func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        initialImage
    }
    
    public func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        loadImages[node.handle] ?? loadImage
    }
}
