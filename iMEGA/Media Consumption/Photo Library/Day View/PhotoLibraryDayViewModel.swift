import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryDayViewModel: PhotoLibraryModeViewModel<PhotosByDay> {
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        libraryViewModel
            .$library
            .map {
                $0.allPhotosByDayList
            }
            .assign(to: &$photoCategoryList)
    }
    
    func didTapDayCard(_ photoByDay: PhotosByDay) {
        libraryViewModel.currentPosition = photoByDay.position
        libraryViewModel.selectedMode = .all
    }
}
