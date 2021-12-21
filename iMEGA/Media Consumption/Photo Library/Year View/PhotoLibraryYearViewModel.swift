import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryYearViewModel: PhotoLibraryModeCardViewModel<PhotosByYear> {
    override var position: PhotoScrollPosition? {
        guard let photoPosition = libraryViewModel.photoScrollPosition else {
            return super.position
        }
        
        guard let cardPosition = libraryViewModel.cardScrollPosition else {
            guard let category = photoCategoryList.first(where: { $0.categoryDate == photoPosition.date.removeMonth() }) else {
                return nil
            }
            
            return category.position
        }
        
        return cardPosition
    }
    
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        libraryViewModel
            .$library
            .map {
                $0.allphotosByYearList
            }
            .assign(to: &$photoCategoryList)
    }
    
    func didTapYearCard(_ photosByYear: PhotosByYear) {
        libraryViewModel.cardScrollPosition = photosByYear.position
        libraryViewModel.selectedMode = .month
    }
}
