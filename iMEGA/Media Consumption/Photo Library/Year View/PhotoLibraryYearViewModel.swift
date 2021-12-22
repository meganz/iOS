import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryYearViewModel: PhotoLibraryModeCardViewModel<PhotosByYear> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) { $0.removeMonth() }
        
        libraryViewModel
            .$library
            .map {
                $0.allphotosByYearList
            }
            .assign(to: &$photoCategoryList)
    }
    
    override func didTapCategory(_ category: PhotosByYear) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .month
    }
}
