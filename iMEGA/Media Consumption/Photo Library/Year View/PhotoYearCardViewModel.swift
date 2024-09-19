import Combine
import Foundation
import MEGADomain
import MEGAPresentation

final class PhotoYearCardViewModel: PhotoCardViewModel {
    private let photoByYear: PhotoByYear
    
    let title: String
    
    init(photoByYear: PhotoByYear,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.photoByYear = photoByYear
        
        title = photoByYear.categoryDate.formatted(.dateTime.year().locale(.current))
        
        super.init(
            coverPhoto: photoByYear.coverPhoto,
            thumbnailLoader: thumbnailLoader,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
    }
}
