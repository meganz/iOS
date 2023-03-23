import Foundation
import Combine
import SwiftUI

@objc final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    private let selectLimit: Int?
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    @Published var showFilter = false
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    let contentMode: PhotoLibraryContentMode
    
    lazy var selection = PhotoSelection(selectLimit: selectLimit)
    lazy var filterViewModel = PhotoLibraryFilterViewModel(contentMode: contentMode)
    
    // MARK: - Init
    init(library: PhotoLibrary, contentMode: PhotoLibraryContentMode = .library,
         selectLimit: Int? = nil) {
        self.library = library
        self.contentMode = contentMode
        self.selectLimit = selectLimit
        
        super.init()
    }
}
