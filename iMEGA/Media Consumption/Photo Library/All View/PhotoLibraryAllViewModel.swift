import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryAllViewModel: PhotoLibraryModeViewModel<PhotosMonthSection> {
    
    override var position: PhotoScrollPosition? {
        guard let photoPosition = libraryViewModel.photoScrollPosition else {
            return libraryViewModel.cardScrollPosition
        }
        
        guard let cardPosition = libraryViewModel.cardScrollPosition else {
            return photoPosition
        }
        
        let photosByDayList = photoCategoryList.flatMap { $0.photosByMonth.photosByDayList }
        
        guard let dayCategory = photosByDayList.first(where: { $0.categoryDate == cardPosition.date.removeTimestamp() }) else {
            return cardPosition
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
                let previousPhotoPosition = libraryViewModel.photoScrollPosition
                self?.scrollCalculator.calculateScrollPosition(&libraryViewModel.photoScrollPosition)
                
                if previousPhotoPosition != libraryViewModel.photoScrollPosition {
                    // Clear card scroll position when photo scroll position changes
                    libraryViewModel.cardScrollPosition = nil
                }
            }
            .store(in: &subscriptions)
    }
}
