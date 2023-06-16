import Foundation
import Combine
import SwiftUI
import MEGADomain

@objc final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published var library: PhotoLibrary
    @Published var selectedMode: PhotoLibraryViewMode = .all
    @Published var showFilter = false
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    let contentMode: PhotoLibraryContentMode
    let contentConfig: PhotoLibraryContentConfig?
    
    lazy var selection = PhotoSelection(selectLimit: contentConfig?.selectLimit)
    lazy var filterViewModel = PhotoLibraryFilterViewModel(
        contentMode: contentMode,
        userAttributeUseCase: UserAttributeUseCase(repo: UserAttributeRepository.newRepo)
    )
    
    // MARK: - Init
    init(library: PhotoLibrary, contentMode: PhotoLibraryContentMode = .library,
         contentConfig: PhotoLibraryContentConfig? = nil) {
        self.library = library
        self.contentMode = contentMode
        self.contentConfig = contentConfig
        
        super.init()
    }
}
