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
    let configuration: PhotoLibraryContentConfiguration?
    
    lazy var selection = PhotoSelection(selectLimit: configuration?.selectLimit)
    lazy var filterViewModel = PhotoLibraryFilterViewModel(
        contentMode: contentMode,
        userAttributeUseCase: UserAttributeUseCase(repo: UserAttributeRepository.newRepo)
    )
    
    // MARK: - Init
    init(library: PhotoLibrary, contentMode: PhotoLibraryContentMode = .library,
         configuration: PhotoLibraryContentConfiguration? = nil) {
        self.library = library
        self.contentMode = contentMode
        self.configuration = configuration
        
        super.init()
    }
}
