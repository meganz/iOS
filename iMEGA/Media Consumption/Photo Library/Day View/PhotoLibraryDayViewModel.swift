import Foundation

final class PhotoLibraryDayViewModel: PhotoLibraryModeViewModel<PhotosByDay> {
    override var position: PhotoScrollPosition {
        if let date = libraryViewModel.currentPosition {
            return date.removeTimestamp()
        } else {
            return super.position
        }
    }
    
    func didTapDayCard(_ photoByDay: PhotosByDay) {
        libraryViewModel.currentPosition = photoByDay.coverPhoto?.createTime
        libraryViewModel.selectedMode = .all
    }
}
