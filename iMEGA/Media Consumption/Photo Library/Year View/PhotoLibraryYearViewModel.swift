import Foundation

final class PhotoLibraryYearViewModel: PhotoLibraryModeViewModel<PhotosByYear> {
    func didTapYearCard(_ photosByYear: PhotosByYear) {
        libraryViewModel.currentPosition = photosByYear.position
        libraryViewModel.selectedMode = .month
    }
}
