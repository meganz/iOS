import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryAllViewModel: PhotoLibraryModeViewModel<PhotosMonthSection> {
    
    override var position: PhotoScrollPosition? {
        guard let photoPosition = libraryViewModel.photoScrollPosition else {
            return super.position
        }
        
        guard let cardPosition = libraryViewModel.cardScrollPosition else {
            return nil
        }
        
        guard let category = photoCategoryList.first(where: { $0.categoryDate == cardPosition.date.removeDay() }) else {
            return nil
        }
        
        guard category.photosByMonth.allPhotos.first(where: { $0.handle == photoPosition.handle }) != nil else {
            return cardPosition
        }
        
        return photoPosition
    }
    
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        libraryViewModel
            .$library
            .map {
                $0.allPhotosMonthSections
            }
            .assign(to: &$photoCategoryList)
        
        
        libraryViewModel
            .$selectedMode
            .dropFirst()
            .sink { [weak self] _ in
                self?.scrollCalculator.calculateScrollPosition(&libraryViewModel.photoScrollPosition)
                libraryViewModel.cardScrollPosition = nil
            }
            .store(in: &subscriptions)
    }
}
