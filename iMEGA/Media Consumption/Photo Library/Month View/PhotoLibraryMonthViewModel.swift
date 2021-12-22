import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryMonthViewModel: PhotoLibraryModeCardViewModel<PhotosByMonth> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) { $0.removeDay() }
        
        libraryViewModel
            .$library
            .map {
                $0.allPhotosByMonthList
            }
            .assign(to: &$photoCategoryList)
    }
    
    override func didTapCategory(_ category: PhotosByMonth) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .day
    }
}
