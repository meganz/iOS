@testable import MEGA
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

struct MockThumbnailLoader: ThumbnailLoaderProtocol {
    private let initialImage: any ImageContaining
    private let loadImage: AnyAsyncSequence<any ImageContaining>
    
    init(initialImage: any ImageContaining = ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder),
         loadImage: AnyAsyncSequence<any ImageContaining> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.initialImage = initialImage
        self.loadImage = loadImage
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> any ImageContaining {
        initialImage
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        loadImage
    }
}
