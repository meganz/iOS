import Foundation

final class PhotoLibraryYearViewModel: PhotoLibraryModeCardViewModel<PhotoByYear> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) {
            $0.removeMonth()
        } categoryListTransformation: {
            $0.photoByYearList
        }
    }
    
    override func didTapCategory(_ category: PhotoByYear) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .month
    }
}
