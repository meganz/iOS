import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryDayViewModel: PhotoLibraryModeCardViewModel<PhotosByDay> {
    override var position: PhotoScrollPosition? {
        guard let photoPosition = libraryViewModel.photoScrollPosition else {
            return super.position
        }
        
        guard let cardPosition = libraryViewModel.cardScrollPosition else {
            guard let category = photoCategoryList.first(where: { $0.categoryDate == photoPosition.date.removeTimestamp() }) else {
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
                $0.allPhotosByDayList
            }
            .assign(to: &$photoCategoryList)
    }
    
    func didTapDayCard(_ photoByDay: PhotosByDay) {
        libraryViewModel.cardScrollPosition = photoByDay.position
        libraryViewModel.selectedMode = .all
    }
}
