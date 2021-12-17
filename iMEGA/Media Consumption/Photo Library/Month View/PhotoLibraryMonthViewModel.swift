import Foundation

final class PhotoLibraryMonthViewModel: PhotoLibraryModeViewModel<PhotosByMonth> {
    func didTapMonthCard(_ photoByMonth: PhotosByMonth) {
        libraryViewModel.currentPosition = photoByMonth.position
        libraryViewModel.selectedMode = .day
    }
}
