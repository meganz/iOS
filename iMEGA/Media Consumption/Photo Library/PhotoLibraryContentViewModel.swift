import Combine
import Foundation
import MEGADomain
import MEGASDKRepo
import SwiftUI

@MainActor
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
        contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
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

extension PhotoLibraryContentViewModel {
    var shouldShowPhotoLibraryPicker: Bool {
        ![.album, .albumLink].contains(contentMode)
    }
    
    func toggleSelectAllPhotos() {
        let allSelectedCurrently = selection.photos.count == library.allPhotos.count
        selection.allSelected = !allSelectedCurrently
        
        if selection.allSelected {
            selection.setSelectedPhotos(library.allPhotos)
        }
    }
}
