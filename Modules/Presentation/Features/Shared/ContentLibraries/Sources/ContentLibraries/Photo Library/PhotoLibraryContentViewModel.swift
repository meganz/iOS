import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

@MainActor
@objc public final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published public var library: PhotoLibrary
    @Published public var selectedMode: PhotoLibraryViewMode = .all
    @Published public var showFilter = false
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    public let contentMode: PhotoLibraryContentMode
    let configuration: PhotoLibraryContentConfiguration?
    
    public lazy var selection = PhotoSelection(selectLimit: configuration?.selectLimit)
    
    public lazy var filterViewModel = PhotoLibraryFilterViewModel(
        contentMode: contentMode,
        contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
    )
    
    // MARK: - Init
    public init(library: PhotoLibrary,
                contentMode: PhotoLibraryContentMode = .library,
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
    
    public func toggleSelectAllPhotos() {
        let allSelectedCurrently = selection.photos.count == library.allPhotos.count
        selection.allSelected = !allSelectedCurrently
        
        if selection.allSelected {
            selection.setSelectedPhotos(library.allPhotos)
        }
    }
}
