import Foundation

@available(iOS 14.0, *)
@MainActor
final class PhotoLibraryDayViewModel: PhotoLibraryModeCardViewModel<PhotoByDay> {
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel) {
            $0.removeTimestamp()
        } categoryListTransformation: {
            $0.allPhotosByDayList
        }
    }
    
    override func didTapCategory(_ category: PhotoByDay) {
        super.didTapCategory(category)
        libraryViewModel.selectedMode = .all
    }
}
