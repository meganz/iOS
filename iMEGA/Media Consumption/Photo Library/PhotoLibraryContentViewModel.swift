import Foundation

final class PhotoLibraryContentViewModel: ObservableObject {
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    var currentScrollPositionId: PhotoPositionId = nil
    
    init(library: PhotoLibrary) {
        self.library = library
    }
}
