import Foundation
import Combine
import SwiftUI

@available(iOS 14.0, *)
@MainActor
class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private var placeholderImageContainer = ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)
    private var loadingTask: Task<Void, Never>?
    
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
            loadingTask = Task {
                await loadThumbnailFromRemote(for: photo)
            }
        }
    }
    
    func cancel() {
        loadingTask?.cancel()
    }
    
    // MARK: - Private
    
    private func loadThumbnailFromRemote(for photo: NodeEntity) async {
        do {
            for try await url in thumbnailUseCase.loadPreview(for: photo) {
                if let image = Image(contentsOfFile: url.path)  {
                    thumbnailContainer = ImageContainer(image: image)
                }
            }
        } catch {
            MEGALogDebug("[Photos Card:] \(error) happened when loadThumbnailFromRemote.")
        }
    }
}
