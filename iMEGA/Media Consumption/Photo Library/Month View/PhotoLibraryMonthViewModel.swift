import Foundation

final class PhotoLibraryMonthViewModel: PhotoLibraryModeViewModel<PhotosByMonth> {
    override var position: PhotoScrollPosition {
        if let date = libraryViewModel.currentPosition {
            return date.removeDay()
        } else {
            return super.position
        }
    }
    
    func didTapMonthCard(_ photoByMonth: PhotosByMonth) {
        libraryViewModel.currentPosition = photoByMonth.coverPhoto?.createTime
        libraryViewModel.selectedMode = .day
    }
}
