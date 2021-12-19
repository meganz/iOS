import Foundation

final class PhotoLibraryContentViewModel: ObservableObject {
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    var currentPosition: PhotoScrollPosition = nil
    
    @Published var isEditingMode = false
    
    init(library: PhotoLibrary) {
        self.library = library
    }
}
