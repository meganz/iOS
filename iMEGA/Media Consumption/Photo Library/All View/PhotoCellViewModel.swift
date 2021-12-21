import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()
    private let placeholderImageContainer: ImageContainer

    @Published var thumbnailContainer: ImageContainer
    let isEditingMode: Bool

    init(photo: NodeEntity,
         thumbnailUseCase: ThumbnailUseCaseProtocol,
         isEditingMode: Bool = false) {
        self.photo = photo
        self.thumbnailUseCase = thumbnailUseCase
        self.isEditingMode = isEditingMode
        let placeholderFileType = thumbnailUseCase.thumbnailPlaceholderFileType(forNodeName: photo.name)
        placeholderImageContainer = ImageContainer(image: Image(placeholderFileType), isPlaceholder: true)
        thumbnailContainer = placeholderImageContainer
    }
    
    func loadThumbnail() {
        thumbnailUseCase
            .getCachedThumbnail(for: photo.handle)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map {
                ImageContainer(image: Image(contentsOfFile: $0.path))
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.thumbnailContainer = $0
            }
            .store(in: &subscriptions)
    }
}
