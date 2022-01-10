import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let placeholderThumbnail: ImageContainer

    @Published var thumbnailContainer: ImageContainer
    let isEditingMode: Bool
    
    init(photo: NodeEntity,
         thumbnailUseCase: ThumbnailUseCaseProtocol,
         isEditingMode: Bool = false) {
        self.photo = photo
        self.thumbnailUseCase = thumbnailUseCase
        self.isEditingMode = isEditingMode
        
        let placeholderFileType = thumbnailUseCase.thumbnailPlaceholderFileType(forNodeName: photo.name)
        placeholderThumbnail = ImageContainer(image: Image(placeholderFileType), isPlaceholder: true)
        thumbnailContainer = placeholderThumbnail
    }
    
    func loadThumbnail() {
        guard thumbnailContainer == placeholderThumbnail else {
            return
        }
        
        let cachedThumbnailPath = thumbnailUseCase.cachedThumbnail(for: photo).path
        if let image = Image(contentsOfFile: cachedThumbnailPath) {
            thumbnailContainer = ImageContainer(image: image, overlay: photo.overlay)
        } else {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
                self.loadThumbnailFromRemote()
            }
        }
    }
    
    private func loadThumbnailFromRemote() {
        thumbnailUseCase
            .loadThumbnail(for: photo)
            .delay(for: .seconds(0.3), scheduler: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] in
                ImageContainer(image: Image(contentsOfFile: $0.path), overlay: self?.photo.overlay)
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
}
