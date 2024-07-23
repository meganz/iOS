import Combine
import MEGADomain
import MEGAPresentation

final class AllVideosCollectionViewModel: ObservableObject {

    let thumbnailLoader: any ThumbnailLoaderProtocol
    let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    @Published var videos = [NodeEntity]()
    
    init(
        videos: [NodeEntity],
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) {
        self.videos = videos
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }
}
