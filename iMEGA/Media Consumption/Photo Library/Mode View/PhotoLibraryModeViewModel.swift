import Foundation
import Combine

class PhotoLibraryModeViewModel<T: PhotoChronologicalCategory>: PhotoScrollPositioning, ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    let scrollTracker = PhotoScrollTracker()
    @Published var photoCategoryList = [T]()
    let libraryViewModel: PhotoLibraryContentViewModel
    
    var position: PhotoScrollPosition? { nil }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
    }
}
