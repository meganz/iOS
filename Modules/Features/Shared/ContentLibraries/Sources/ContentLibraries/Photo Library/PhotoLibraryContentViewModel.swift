import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAUIComponent
import SwiftUI

@MainActor
@objc public final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published public var library: PhotoLibrary
    @Published public var selectedMode: PhotoLibraryViewMode = .all
    @Published public var showFilter = false
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    public let contentMode: PhotoLibraryContentMode
    public let globalHeaderType: PhotoGlobalHeaderType
    let configuration: PhotoLibraryContentConfiguration?
    
    public lazy var selection = PhotoSelection(selectLimit: configuration?.selectLimit)
    
    public lazy var filterViewModel = PhotoLibraryFilterViewModel(
        contentMode: contentMode,
        contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
    )
    
    // MARK: - Init
    public init(library: PhotoLibrary,
                contentMode: PhotoLibraryContentMode = .library,
                globalHeaderType: PhotoGlobalHeaderType = .dateAndZoom, // by default, dispaly a date and zoom control
                configuration: PhotoLibraryContentConfiguration? = nil) {
        self.library = library
        self.contentMode = contentMode
        self.globalHeaderType = globalHeaderType
        self.configuration = configuration
        
        super.init()
    }
}

extension PhotoLibraryContentViewModel {
    var shouldShowPhotoLibraryPicker: Bool {
        ![.album, .albumLink].contains(contentMode)
    }
    
    public var isPhotoLibraryEmpty: Bool {
        library.isEmpty
    }
    
    public var appliedMediaTypeFilterOption: PhotosFilterOptions {
        filterViewModel.appliedMediaTypeFilter.toPhotosFilterOptions()
    }
    
    public var appliedLocationFilterOption: PhotosFilterOptions {
        filterViewModel.appliedFilterLocation.toPhotosFilterOptions()
    }
    
    public var selectedPhotos: [NodeEntity] {
        Array(selection.photos.values)
    }
    
    public func toggleSelectAllPhotos() {
        let allSelectedCurrently = selection.photos.count == library.allPhotos.count
        selection.allSelected = !allSelectedCurrently
        
        if selection.allSelected {
            selection.setSelectedPhotos(library.allPhotos)
        }
    }
}
