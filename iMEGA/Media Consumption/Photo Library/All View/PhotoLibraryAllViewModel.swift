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
        
        let photosByDayList = photoCategoryList.flatMap { $0.photosByMonth.photosByDayList }
        
        guard let dayCategory = photosByDayList.first(where: { $0.categoryDate == cardPosition.date.removeTimestamp() }) else {
            return nil
        }
        
        guard dayCategory.photoNodeList.first(where: { $0.handle == photoPosition.handle }) != nil else {
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
