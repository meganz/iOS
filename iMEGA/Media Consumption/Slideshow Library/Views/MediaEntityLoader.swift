import Foundation
import MEGADomain

struct MediaEntityLoader: Sendable {
    
    typealias ImageSource = (UIImage, URL?)
    
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let fileDownloadUseCase: any FileDownloadUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    
    init(thumbnailUseCase: some ThumbnailUseCaseProtocol,
         fileDownloadUseCase: some FileDownloadUseCaseProtocol,
         mediaUseCase: some MediaUseCaseProtocol) {

        self.thumbnailUseCase = thumbnailUseCase
        self.mediaUseCase = mediaUseCase
        self.fileDownloadUseCase = fileDownloadUseCase
    }

    func loadMediaEntity(forNode node: NodeEntity) async -> ImageSource? {
        if mediaUseCase.isGifImage(node.name) {
            await downloadGifNode(node: node)
        } else {
            await downloadPhoto(node: node)
        }
    }
    
    private func downloadPhoto(node: NodeEntity) async -> ImageSource? {
        if let photo = try? await thumbnailUseCase.loadThumbnail(for: node, type: .preview),
           let image = UIImage(contentsOfFile: photo.url.path) {
            (image, nil)
        } else {
            nil
        }
    }
    
    private func downloadGifNode(node: NodeEntity) async -> ImageSource? {
        do {
            let url = try await fileDownloadUseCase.downloadNode(node)
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                return nil
            }
            return (image, url)
        } catch {
            MEGALogError(error.localizedDescription)
            return nil
        }
    }
}
