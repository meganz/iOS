import Foundation

final class PhotoLibraryYearViewModel: PhotoLibraryModeViewModel<PhotosByYear> {
    override var position: PhotoScrollPosition {
        if let date = libraryViewModel.currentPosition {
            return date.removeMonth()
        } else {
            return super.position
        }
    }

    func didTapYearCard(_ photosByYear: PhotosByYear) {
        libraryViewModel.currentPosition = photosByYear.coverPhoto?.createTime
        libraryViewModel.selectedMode = .month
    }
}
