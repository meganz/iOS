import Combine
import Foundation
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private var placeholderImageContainer = ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)
    
    @Published var thumbnailContainer: any ImageContaining
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
        thumbnailContainer = placeholderImageContainer
    }
    
    func loadThumbnail() async {
        guard let photo = coverPhoto,
              isShowingThumbnail(placeholderImageContainer) else {
            return
        }
        
        if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .preview) {
            return await updateThumbnailContainerIfNeeded(container)
        }
        
        do {
            try await requestThumbnailPreview(photo: photo)
        } catch {
            MEGALogDebug("[PhotoCardViewModel] Cancelled loading thumbnail for \(photo.handle)")
        }
    }
    
    // MARK: - Private
    private func requestThumbnailPreview(photo: NodeEntity) async throws {
        for try await imageContainer in thumbnailUseCase.requestPreview(for: photo)
            .compactMap({ $0.toURLImageContainer()}) {
            try Task.checkCancellation()
            await updateThumbnailContainerIfNeeded(imageContainer)
        }
    }
    
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
