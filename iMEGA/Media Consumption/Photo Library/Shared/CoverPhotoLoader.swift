import Foundation
import Combine

final class CoverPhotoLoader {
    private var subscription: AnyCancellable?
    
    let coverPhoto: NodeEntity?
    let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    func loadCoverPhoto() -> AnyPublisher<URL?, Never> {
        let subject = CurrentValueSubject<URL?, Never>(nil)
        
        if let handle = coverPhoto?.handle {
            subscription =
            thumbnailUseCase
                .getCachedThumbnailAndPreview(for: handle)
                .sink { _ in
                } receiveValue: { output in
                    if let url = output.1 {
                        subject.send(url)
                    } else if let url = output.0 {
                        subject.send(url)
                    } else {
                        subject.send(nil)
                    }
                }
        }
        
        return subject.eraseToAnyPublisher()
    }
}
