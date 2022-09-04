import Foundation
import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain

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
        
        if let container = thumbnailUseCase.cachedThumbnailImageContainer(for: photo, type: .preview) {
            thumbnailContainer = container
        } else {
            loadThumbnailFromRemote(for: photo)
        }
    }
    
    // MARK: - Private
    private func loadThumbnailFromRemote(for photo: NodeEntity) {
        thumbnailUseCase
            .requestPreview(for: photo)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map { url in
                URLImageContainer(imageURL: url)
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
