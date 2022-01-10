import Foundation
import Combine
import SwiftUI

@available(iOS 14.0, *)
class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private var placeholderImageContainer = ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)
    
    @Published var thumbnailContainer: ImageContainer
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
        thumbnailContainer = placeholderImageContainer
    }
    
    func loadThumbnail() {
        guard let photo = coverPhoto else {
            return
        }
        
        guard thumbnailContainer == placeholderImageContainer else {
            return
        }
        
        let cachedPreviewPath = thumbnailUseCase.cachedPreview(for: photo).path
        if let image = Image(contentsOfFile: cachedPreviewPath) {
            thumbnailContainer = ImageContainer(image: image, overlay: photo.overlay)
        } else {
            loadThumbnailFromRemote(for: photo)
        }
    }
    
    private func loadThumbnailFromRemote(for photo: NodeEntity) {
        thumbnailUseCase
            .loadThumbnailAndPreview(for: photo)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map { (thumbnailURL, previewURL) -> URL? in
                if let url = previewURL {
                    return url
                } else if let url = thumbnailURL {
                    return url
                } else {
                    return nil
                }
            }
            .replaceError(with: nil)
            .compactMap { [weak self] in
                ImageContainer(image: Image(contentsOfFile: $0?.path), overlay: self?.coverPhoto?.overlay)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
}
