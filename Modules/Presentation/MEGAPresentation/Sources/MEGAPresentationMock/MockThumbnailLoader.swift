import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

public final class MockThumbnailLoader: ThumbnailLoaderProtocol, @unchecked Sendable {
    private let initialImage: (any ImageContaining)?
    private let loadImage: AnyAsyncSequence<any ImageContaining>
    private let loadImages: [HandleEntity: AnyAsyncSequence<any ImageContaining>]
    
    public enum Invocation: Equatable, Sendable {
        case initialImageWithPlaceholder
        case loadImage
    }
    
    @Atomic public var invocations: [Invocation] = []
    
    public init(initialImage: (any ImageContaining)? = ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder),
                loadImage: AnyAsyncSequence<any ImageContaining> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
                loadImages: [HandleEntity: AnyAsyncSequence<any ImageContaining>] = [:]) {
        self.initialImage = initialImage
        self.loadImage = loadImage
        self.loadImages = loadImages
    }
    
    public func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        initialImage ?? ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)
    }
    
    public func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        $invocations.mutate { $0.append(.initialImageWithPlaceholder) }
        return initialImage ?? ImageContainer(image: placeholder(), type: type.toImageType())
    }
    
    public func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        $invocations.mutate { $0.append(.loadImage) }
        return loadImages[node.handle] ?? loadImage
    }
}
