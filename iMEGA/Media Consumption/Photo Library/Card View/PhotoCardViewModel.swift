import Foundation
import Combine
import SwiftUI
import MEGASwiftUI

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
        
        if let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: .preview) {
            thumbnailContainer = ImageContainer(image: image)
        } else {
            loadThumbnailFromRemote(for: photo)
        }
    }
    
    // MARK: - Private
    private func loadThumbnailFromRemote(for photo: NodeEntity) {
        thumbnailUseCase
            .requestPreview(for: photo)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map { photo in
                ImageContainer(image: Image(contentsOfFile: photo.path))
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .filter { [weak self] in
                $0 != self?.thumbnailContainer
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
}
