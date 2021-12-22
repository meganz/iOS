import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryDayViewModel: PhotoLibraryModeCardViewModel<PhotosByDay> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) { $0.removeTimestamp() }
        
        libraryViewModel
            .$library
            .map {
                $0.allPhotosByDayList
            }
            .assign(to: &$photoCategoryList)
    }
    
    override func didTapCategory(_ category: PhotosByDay) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .all
    }
}
