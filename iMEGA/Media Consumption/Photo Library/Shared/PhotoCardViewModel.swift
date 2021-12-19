import Foundation
import Combine
import SwiftUI

@available(iOS 14.0, *)
class PhotoCardViewModel: ObservableObject {
    private let coverPhotoLoader: CoverPhotoLoader
    private let coverPhoto: NodeEntity?
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()
    private var placeholderImageContainer = ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)
    
    @Published var thumbnailContainer: ImageContainer
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
        self.coverPhotoLoader = CoverPhotoLoader(coverPhoto: coverPhoto, thumbnailUseCase: thumbnailUseCase)
        thumbnailContainer = placeholderImageContainer
    }
    
    func loadThumbnail() {
        coverPhotoLoader
            .loadCoverPhoto()
            .receive(on: DispatchQueue.global(qos: .utility))
            .compactMap {
                ImageContainer(image: Image(contentsOfFile: $0?.path))
            }
            .delay(for: .seconds(0.07), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.thumbnailContainer = $0
            }
            .store(in: &subscriptions)
    }
    
    func resetThumbnail() {
        subscriptions.removeAll()
        thumbnailContainer = placeholderImageContainer
    }
}
