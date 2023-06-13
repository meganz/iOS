import Foundation
import Combine
import MEGADomain

final class PhotoYearCardViewModel: PhotoCardViewModel {
    private let photoByYear: PhotoByYear
    
    let title: String
    
    init(photoByYear: PhotoByYear,
         thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.photoByYear = photoByYear
        
        if #available(iOS 15.0, *) {
            title = photoByYear.categoryDate.formatted(.dateTime.year().locale(.current))
        } else {
            title = DateFormatter.yearTemplate().localisedString(from: photoByYear.categoryDate)
        }
        
        super.init(coverPhoto: photoByYear.coverPhoto, thumbnailUseCase: thumbnailUseCase)
    }
}
