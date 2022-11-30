import Foundation

final class PhotoLibraryMonthViewModel: PhotoLibraryModeCardViewModel<PhotoByMonth> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) {
            $0.removeDay()
        } categoryListTransformation: {
            $0.photosByMonthList
        }
    }
    
    override func didTapCategory(_ category: PhotoByMonth) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .day
    }
}
