import Foundation
import MEGADomain
import MEGAPresentation

final class PhotoDayCardViewModel: PhotoCardViewModel {
    private let photoByDay: PhotoByDay
    
    let title: String
    
    var badgeTitle: String? {
        return photoByDay.contentList.count > 1 ? "+\(photoByDay.contentList.count - 1)": nil
    }
    
    var attributedTitle: AttributedString {
        var attr = photoByDay.categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).day().attributed)
        let bold = AttributeContainer.font(.title2.bold())
        attr.replaceAttributes(AttributeContainer.dateField(.month), with: bold)
        attr.replaceAttributes(AttributeContainer.dateField(.day), with: bold)
        
        return attr
    }
    
    init(photoByDay: PhotoByDay,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.photoByDay = photoByDay
        title = DateFormatter.dateLong().localisedString(from: photoByDay.categoryDate)
        
        super.init(coverPhoto: photoByDay.coverPhoto, thumbnailLoader: thumbnailLoader, nodeUseCase: nodeUseCase, featureFlagProvider: featureFlagProvider)
    }
}
