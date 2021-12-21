import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryYearViewModel: PhotoLibraryModeViewModel<PhotosByYear> {
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
        libraryViewModel.currentPosition = photosByYear.position
        libraryViewModel.selectedMode = .month
    }
}
