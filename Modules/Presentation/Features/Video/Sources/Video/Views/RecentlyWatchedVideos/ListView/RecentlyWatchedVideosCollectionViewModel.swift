import Combine
import MEGADomain
import MEGAPresentation

final class RecentlyWatchedVideosCollectionViewModel: ObservableObject {

    let thumbnailLoader: any ThumbnailLoaderProtocol
    let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    let nodeUseCase: any NodeUseCaseProtocol
    let featureFlagProvier: any FeatureFlagProviderProtocol
    @Published var sections = [RecentlyWatchedVideoSection]()
    
    init(
        sections: [RecentlyWatchedVideoSection],
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvier: some FeatureFlagProviderProtocol
    ) {
        self.sections = sections
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvier = featureFlagProvier
    }
}
