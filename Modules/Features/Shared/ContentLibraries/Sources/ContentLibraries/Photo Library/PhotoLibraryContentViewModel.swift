import Combine
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAUIComponent
import SwiftUI

@MainActor
@objc public final class PhotoLibraryContentViewModel: NSObject, ObservableObject {
    @Published public var library: PhotoLibrary
    @Published public var selectedMode: PhotoLibraryViewMode = .all {
        didSet {
            guard selectedMode != oldValue else { return }
            tracker.trackViewModeChange(selectedMode)
        }
    }
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
    
    private let tracker: any AnalyticsTracking
    
    lazy var allCollectionViewModel = PhotoLibraryModeAllCollectionViewModel(libraryViewModel: self)
    
    // MARK: - Init
    public init(
        library: PhotoLibrary,
        contentMode: PhotoLibraryContentMode = .library,
        globalHeaderType: PhotoGlobalHeaderType = .dateAndZoom, // by default, display a date and zoom control
        configuration: PhotoLibraryContentConfiguration? = nil,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.library = library
        self.contentMode = contentMode
        self.globalHeaderType = globalHeaderType
        self.configuration = configuration
        self.tracker = tracker
        
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
