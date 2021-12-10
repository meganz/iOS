import Foundation
import Combine

@available(iOS 14.0, *)
final class PhotoYearCardViewModel: PhotoCardViewModel {
    private let photosByYear: PhotosByYear
    
    let title: String
    
    init(photosByYear: PhotosByYear,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photosByYear = photosByYear
        
        if #available(iOS 15.0, *) {
            title = photosByYear.year.formatted(.dateTime.year().locale(.current))
        } else {
            title = DateFormatter.yearTemplate().localisedString(from: photosByYear.year)
        }
        
        super.init(coverPhoto: photosByYear.coverPhoto, thumbnailUseCase: thumbnailUseCase)
    }
}
