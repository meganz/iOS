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
        } else if let isSensitive = sensitiveNodeUseCase.cachedInheritedSensitivity(for: node.handle) {
            /// Currently, when there is sdk updates related to media node, the collectionView will be reloaded (check `PhotoLibraryCollectionViewLayoutChangesMonitor`)
            /// This results in new instances of `PhotoCellContent` and `PhotoCellViewModel` are created (check the cell registration in `PhotoLibraryCollectionViewCoordinator`)
            /// In `PhotoCellViewModel`'s init, this `initialImage` function will be called for each refreshed NodeEntity.
            /// Since the node inherited sensitivity state loading is async, we need to show the placeholder (the else branch below) first while waiting.
            /// Once the inherited sensitivity state loading completes, the placeholder will be replaced with the loaded thumbnail, hence the flickering
            /// So the workaround fix the flickering is to cache the inherited sensitivity state.
            /// Details in the jira ticket CC-8509.
            initialImage
                .toSensitiveImageContaining(isSensitive: isSensitive)
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
