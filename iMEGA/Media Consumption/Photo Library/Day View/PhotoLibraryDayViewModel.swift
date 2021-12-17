import Foundation

final class PhotoLibraryDayViewModel: PhotoLibraryModeViewModel<PhotosByDay> {
    func didTapDayCard(_ photoByDay: PhotosByDay) {
        libraryViewModel.currentPosition = photoByDay.position
        libraryViewModel.selectedMode = .all
    }
}
