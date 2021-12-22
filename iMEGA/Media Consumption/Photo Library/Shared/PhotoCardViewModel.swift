import Foundation
import Combine
import SwiftUI

@available(iOS 14.0, *)
class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()
    private var placeholderImageContainer = ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)
    
    @Published var thumbnailContainer: ImageContainer
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
        thumbnailContainer = placeholderImageContainer
    }
    
    func loadThumbnail() {
        guard let handle = coverPhoto?.handle else {
            return
        }
        
        thumbnailUseCase
            .getCachedThumbnailAndPreview(for: handle)
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
            .receive(on: DispatchQueue.global(qos: .utility))
            .compactMap { [weak self] in
                ImageContainer(image: Image(contentsOfFile: $0?.path), overlay: self?.coverPhoto?.overlay)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.thumbnailContainer = $0
            }
            .store(in: &subscriptions)
    }
}
