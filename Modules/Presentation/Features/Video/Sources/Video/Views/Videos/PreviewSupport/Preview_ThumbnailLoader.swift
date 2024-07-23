import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

struct Preview_ThumbnailLoader: ThumbnailLoaderProtocol {
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        ImageContainer(image: Image(.black), type: type.toImageType())
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        SingleItemAsyncSequence(item: ImageContainer(image: Image(.black), type: type.toImageType()))
            .eraseToAnyAsyncSequence()
    }
}
