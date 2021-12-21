import Foundation

@available(iOS 14.0, *)
final class PhotoLibraryMonthViewModel: PhotoLibraryModeViewModel<PhotosByMonth> {
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        libraryViewModel
            .$library
            .map {
                $0.allPhotosByMonthList
            }
            .assign(to: &$photoCategoryList)
    }
    
    func didTapMonthCard(_ photoByMonth: PhotosByMonth) {
        libraryViewModel.currentPosition = photoByMonth.position
        libraryViewModel.selectedMode = .day
    }
}
