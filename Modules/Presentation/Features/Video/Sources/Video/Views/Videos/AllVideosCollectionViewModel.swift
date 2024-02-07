import Combine
import MEGADomain

final class AllVideosCollectionViewModel: ObservableObject {
    let thumbnailUseCase: any ThumbnailUseCaseProtocol
    @Published var videos = [NodeEntity]()
    
    init(thumbnailUseCase: some ThumbnailUseCaseProtocol, videos: [NodeEntity]) {
        self.thumbnailUseCase = thumbnailUseCase
        self.videos = videos
    }
}
