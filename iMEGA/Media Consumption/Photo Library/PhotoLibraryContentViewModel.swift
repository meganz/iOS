import Foundation

@objc final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    
    @Published var isEditingMode = false
    
    init(library: PhotoLibrary) {
        self.library = library
        super.init()
    }
}
