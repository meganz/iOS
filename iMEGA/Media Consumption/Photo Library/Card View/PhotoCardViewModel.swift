import Foundation
import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain
import MEGASwift

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
    
    func loadThumbnail() {
        guard let photo = coverPhoto else {
            return
        }
        
        guard isShowingThumbnail(placeholderImageContainer) else {
            return
        }
        
        if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .preview) {
            thumbnailContainer = container
        } else {
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                thumbnailContainer = container
            }
            
            loadThumbnailFromRemote(for: photo)
        }
    }
    
    // MARK: - Private
    private func loadThumbnailFromRemote(for photo: NodeEntity) {
        thumbnailUseCase
            .requestPreview(for: photo)
            .map {
                $0.toURLImageContainer()
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .filter { [weak self] in
                self?.isShowingThumbnail($0) == false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
    
    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
}
