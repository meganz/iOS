import Combine
import Foundation

@MainActor
public class PhotoLibraryModeViewModel<T: PhotoChronologicalCategory>: ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    let scrollTracker = PhotoScrollTracker()
    @Published var photoCategoryList = [T]()
    let libraryViewModel: PhotoLibraryContentViewModel
    
    var position: PhotoScrollPosition? { nil }
    
    public init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
    }
}
