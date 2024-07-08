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
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.photoByYear = photoByYear
        
        title = photoByYear.categoryDate.formatted(.dateTime.year().locale(.current))
        
        super.init(coverPhoto: photoByYear.coverPhoto, thumbnailLoader: thumbnailLoader, nodeUseCase: nodeUseCase, featureFlagProvider: featureFlagProvider)
    }
}
