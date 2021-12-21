import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryMonthViewModel: PhotoLibraryModeCardViewModel<PhotosByMonth> {
    override var position: PhotoScrollPosition? {
        guard let photoPosition = libraryViewModel.photoScrollPosition else {
            return super.position
        }
        
        guard let cardPosition = libraryViewModel.cardScrollPosition else {
            guard let category = photoCategoryList.first(where: { $0.categoryDate == photoPosition.date.removeDay() }) else {
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
                $0.allPhotosByMonthList
            }
            .assign(to: &$photoCategoryList)
    }
    
    func didTapMonthCard(_ photoByMonth: PhotosByMonth) {
        libraryViewModel.cardScrollPosition = photoByMonth.position
        libraryViewModel.selectedMode = .day
    }
}
