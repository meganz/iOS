import Foundation

final class PhotoLibraryAllViewModel: PhotoLibraryModeViewModel<PhotosMonthSection> {
    override var position: PhotoScrollPosition {
        if let date = libraryViewModel.currentPosition {
            return date
        } else {
            return super.position
        }
    }
}
