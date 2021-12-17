import Foundation

class PhotoLibraryModeViewModel<T: PhotosChronologicalCategory>: ScrollPositioning, ObservableObject {
    @Published var photoCategoryList: [T]
    let libraryViewModel: PhotoLibraryContentViewModel
    
    var position: PhotoScrollPosition {
        libraryViewModel.currentPosition
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel, photoCategoryList: [T]) {
        self.libraryViewModel = libraryViewModel
        self.photoCategoryList = photoCategoryList
    }
}
