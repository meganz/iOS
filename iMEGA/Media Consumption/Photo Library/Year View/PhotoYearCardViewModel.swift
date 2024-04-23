import Combine
import Foundation
import MEGADomain

final class PhotoYearCardViewModel: PhotoCardViewModel {
    private let photoByYear: PhotoByYear
    
    let title: String
    
    init(photoByYear: PhotoByYear,
         thumbnailLoader: some ThumbnailLoaderProtocol) {
        self.photoByYear = photoByYear
        
        title = photoByYear.categoryDate.formatted(.dateTime.year().locale(.current))
        
        super.init(coverPhoto: photoByYear.coverPhoto, thumbnailLoader: thumbnailLoader)
    }
}
