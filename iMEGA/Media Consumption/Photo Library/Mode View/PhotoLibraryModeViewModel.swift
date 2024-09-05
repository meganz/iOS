import Combine
import Foundation

@MainActor
class PhotoLibraryModeViewModel<T: PhotoChronologicalCategory>: ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    let scrollTracker = PhotoScrollTracker()
    @Published var photoCategoryList = [T]()
    let libraryViewModel: PhotoLibraryContentViewModel
    
    var position: PhotoScrollPosition? { nil }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
    }
}
