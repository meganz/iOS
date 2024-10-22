import Foundation
import MEGADomain
import MEGAPresentation

final class PhotoMonthCardViewModel: PhotoCardViewModel {
    private let photoByMonth: PhotoByMonth
    
    let title: String
    
    var attributedTitle: AttributedString {
        var attr = photoByMonth.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(month, with: bold)
        
        return attr
    }

    init(photoByMonth: PhotoByMonth,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.photoByMonth = photoByMonth
        title = DateFormatter.monthTemplate().localisedString(from: photoByMonth.categoryDate)
        
        super.init(
            coverPhoto: photoByMonth.coverPhoto,
            thumbnailLoader: thumbnailLoader,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
        )
    }
}
