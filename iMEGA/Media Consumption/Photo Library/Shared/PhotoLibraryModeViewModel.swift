import Foundation
import Combine

class PhotoLibraryModeViewModel<T: PhotosChronologicalCategory>: ScrollPositioning, ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    let scrollCalculator = ScrollPositionCalculator()
    @Published var photoCategoryList = [T]()
    let libraryViewModel: PhotoLibraryContentViewModel
    
    var position: PhotoScrollPosition? {
        libraryViewModel.cardScrollPosition
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
    }
}
