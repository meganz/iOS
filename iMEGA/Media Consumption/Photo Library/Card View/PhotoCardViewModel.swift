import Combine
import Foundation
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    
    @Published var thumbnailContainer: any ImageContaining
    
    init(coverPhoto: NodeEntity?,
         thumbnailLoader: some ThumbnailLoaderProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailLoader = thumbnailLoader
        
        thumbnailContainer = if let photo = coverPhoto {
            thumbnailLoader.initialImage(for: photo, type: .preview,
                                         placeholder: { Image(.photoCardPlaceholder) })
        } else {
            ImageContainer(image: Image(.photoCardPlaceholder), type: .placeholder)
        }
    }
    
    func loadThumbnail() async {
        guard let photo = coverPhoto,
              thumbnailContainer.type == .placeholder else {
            return
        }
        do {
            for await imageContainer in try await thumbnailLoader.loadImage(for: photo, type: .preview) {
                await updateThumbnailContainerIfNeeded(imageContainer)
            }
        } catch is CancellationError {
            MEGALogDebug("[PhotoCardViewModel] Cancelled loading thumbnail for \(photo.handle)")
        } catch {
            MEGALogError("[PhotoCardViewModel] failed to load preview: \(error)")
        }
    }
    
    // MARK: - Private
    private func updateThumbnailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !isShowingThumbnail(container) else { return }
        await updateThumbnailContainer(container)
    }
    
    @MainActor
    private func updateThumbnailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
    }
    
    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
}
