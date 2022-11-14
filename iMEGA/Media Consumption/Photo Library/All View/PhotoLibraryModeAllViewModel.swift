import Foundation

class PhotoLibraryModeAllViewModel: PhotoLibraryModeViewModel<PhotoDateSection> {
    @Published var zoomState = PhotoLibraryZoomState()
    
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        photoCategoryList = libraryViewModel.library.photoMonthSections
    }
}
