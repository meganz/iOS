import Foundation

final class PhotoLibraryDayViewModel: PhotoLibraryModeCardViewModel<PhotoByDay> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) {
            $0.removeTimestamp()
        } categoryListTransformation: {
            $0.photosByDayList
        }
    }
    
    override func didTapCategory(_ category: PhotoByDay) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .all
    }
}
