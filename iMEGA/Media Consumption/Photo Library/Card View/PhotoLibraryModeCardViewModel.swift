import Foundation
import Combine

@available(iOS 14.0, *)
class PhotoLibraryModeCardViewModel<T: PhotoChronologicalCategory>: PhotoLibraryModeViewModel<T> {
    private let categoryDateTransformation: (Date) -> Date?
    private let categoryListTransformation: (PhotoLibrary) -> [T]
    
    override var position: PhotoScrollPosition? {
        func searchCategoryPosition(by position: PhotoScrollPosition) -> PhotoScrollPosition? {
            guard let category = photoCategoryList.first(where: { $0.categoryDate == categoryDateTransformation(position.date) }) else {
                MEGALogDebug("[Photos] \(libraryViewModel.selectedMode) position - could not find position \(position.date)")
                return position
            }
            
            MEGALogDebug("[Photos] \(libraryViewModel.selectedMode) position - found \(String(describing: category.position?.date))")
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
    
    init(libraryViewModel: PhotoLibraryContentViewModel, categoryDateTransformation: @escaping (Date) -> Date?, categoryListTransformation: @escaping (PhotoLibrary) -> [T]) {
        self.categoryDateTransformation = categoryDateTransformation
        self.categoryListTransformation = categoryListTransformation
        super.init(libraryViewModel: libraryViewModel)
        
        photoCategoryList = categoryListTransformation(libraryViewModel.library)
        
        subscribeToLibraryChange()
        subscribeToSelectedModeChange()
    }
    
    func didTapCategory(_ category: T) {
        scrollTracker.trackTappedPosition(category.position)
    }
    
    private func subscribeToLibraryChange() {
        libraryViewModel
            .$library
            .dropFirst()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .compactMap { [weak self] in
                self?.categoryListTransformation($0)
            }
            .filter { [weak self] in
                let visiblePositions = self?.scrollTracker.visiblePositions ?? [:]
                return self?.photoCategoryList.shouldRefreshTo($0, forVisiblePositions: visiblePositions) == true
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$photoCategoryList)
    }
    
    private func subscribeToSelectedModeChange() {
        libraryViewModel
            .$selectedMode
            .dropFirst()
            .sink { [weak self, libraryViewModel = self.libraryViewModel] in
                self?.scrollTracker.calculateScrollPosition(&libraryViewModel.cardScrollPosition)
                if libraryViewModel.cardScrollPosition == .top {
                    // Clear both card and photo positions when it scrolls to top
                    libraryViewModel.cardScrollPosition = nil
                    libraryViewModel.photoScrollPosition = nil
                }
                
                if $0 == .all {
                    NotificationCenter.default.post(name: .didFinishPhotoCardScrollPositionCalculation, object: nil)
                }
                
                MEGALogDebug("[Photos] \(Self.self) after calculation card:\(String(describing: libraryViewModel.cardScrollPosition?.date)), photo: \(String(describing: libraryViewModel.photoScrollPosition?.date))")
            }
            .store(in: &subscriptions)
    }
}
