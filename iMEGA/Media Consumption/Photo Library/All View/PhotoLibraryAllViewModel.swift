import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryAllViewModel: PhotoLibraryModeViewModel<PhotosMonthSection> {
    
    override var position: PhotoScrollPosition? {
        guard let photoPosition = libraryViewModel.photoScrollPosition else {
            MEGALogDebug("[Photos] uses card position \(String(describing: libraryViewModel.cardScrollPosition?.date))")
            return libraryViewModel.cardScrollPosition
        }
        
        guard let cardPosition = libraryViewModel.cardScrollPosition else {
            MEGALogDebug("[Photos] uses photo position \(String(describing: photoPosition.date))")
            return photoPosition
        }
        
        let photosByDayList = photoCategoryList.flatMap { $0.photosByMonth.photosByDayList }
        guard let dayCategory = photosByDayList.first(where: { $0.categoryDate == cardPosition.date.removeTimestamp() }) else {
            MEGALogDebug("[Photos] can not find day category by card \(String(describing: cardPosition.date))")
            return cardPosition
        }
        
        guard dayCategory.photoNodeList.first(where: { $0.handle == photoPosition.handle }) != nil else {
            MEGALogDebug("[Photos] photo position \(String(describing: photoPosition.date)) is not in card: \(String(describing: cardPosition.date))")
            return cardPosition
        }
        
        MEGALogDebug("[Photos] card contains photo position \(String(describing: photoPosition.date))")
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
                
                if libraryViewModel.photoScrollPosition == .top {
                    // Clear both card and photo positions when it scrolls to top
                    libraryViewModel.cardScrollPosition = nil
                    libraryViewModel.photoScrollPosition = nil
                }
                
                MEGALogDebug("[Photos] after calculation card:\(String(describing: libraryViewModel.cardScrollPosition?.date)), photo: \(String(describing: libraryViewModel.photoScrollPosition?.date))")
            }
            .store(in: &subscriptions)
    }
}
