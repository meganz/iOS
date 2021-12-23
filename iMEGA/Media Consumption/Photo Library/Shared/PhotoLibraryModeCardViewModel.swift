import Foundation
import Combine

class PhotoLibraryModeCardViewModel<T: PhotosChronologicalCategory>: PhotoLibraryModeViewModel<T> {
    private let categoryDateTransformation: (Date) -> Date?
    
    override var position: PhotoScrollPosition? {
        func searchCategoryPosition(by position: PhotoScrollPosition) -> PhotoScrollPosition? {
            guard let category = photoCategoryList.first(where: { $0.categoryDate == categoryDateTransformation(position.date) }) else {
                MEGALogDebug("[Photos] \(libraryViewModel.selectedMode) could not find position \(position.date)")
                return position
            }
            
            MEGALogDebug("[Photos] \(libraryViewModel.selectedMode) position found \(String(describing: category.position?.date))")
            return category.position
        }
        
        if let cardPosition = libraryViewModel.cardScrollPosition {
            return searchCategoryPosition(by: cardPosition)
        } else if let photoPosition = libraryViewModel.photoScrollPosition {
            return searchCategoryPosition(by: photoPosition)
        } else {
            return nil
        }
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel, categoryDateTransformation: @escaping (Date) -> Date?) {
        self.categoryDateTransformation = categoryDateTransformation
        super.init(libraryViewModel: libraryViewModel)
        
        libraryViewModel
            .$selectedMode
            .dropFirst()
            .sink { [weak self] _ in
                self?.scrollCalculator.calculateScrollPosition(&libraryViewModel.cardScrollPosition)
                if libraryViewModel.cardScrollPosition == .top {
                    // When it scrolls to the top, we also clear both card and photo positions
                    libraryViewModel.cardScrollPosition = nil
                    libraryViewModel.photoScrollPosition = nil
                }
                
                MEGALogDebug("[Photos] after calculation card:\(String(describing: libraryViewModel.cardScrollPosition?.date)), photo: \(String(describing: libraryViewModel.photoScrollPosition?.date))")
            }
            .store(in: &subscriptions)
    }
    
    func didTapCategory(_ category: T) {
        scrollCalculator.recordTappedPosition(category.position)
    }
}
