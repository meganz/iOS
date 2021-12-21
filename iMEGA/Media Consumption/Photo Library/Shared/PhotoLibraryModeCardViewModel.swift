import Foundation
import Combine

class PhotoLibraryModeCardViewModel<T: PhotosChronologicalCategory>: PhotoLibraryModeViewModel<T> {
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        libraryViewModel
            .$selectedMode
            .dropFirst()
            .sink { [weak self] _ in
                self?.scrollCalculator.calculateScrollPosition(&libraryViewModel.cardScrollPosition)
            }
            .store(in: &subscriptions)
    }
}
