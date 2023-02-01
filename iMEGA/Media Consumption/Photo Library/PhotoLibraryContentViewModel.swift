import Foundation
import Combine
import SwiftUI

@objc final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    @Published var showFilter = false
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    let contentMode: PhotoLibraryContentMode
    
    lazy var selection = PhotoSelection()
    lazy var filterViewModel = PhotoLibraryFilterViewModel(contentMode: contentMode)
    
    // MARK: - Init
    init(library: PhotoLibrary, contentMode: PhotoLibraryContentMode = .library) {
        self.library = library
        self.contentMode = contentMode
        
        super.init()
    }
}
