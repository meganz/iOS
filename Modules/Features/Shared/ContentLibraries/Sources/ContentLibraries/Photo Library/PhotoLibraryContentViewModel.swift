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
    @Published public var isLoading = true
    
    public let visiblePhotoIndexRange = CurrentValueSubject<Range<Int>?, Never>(nil)

    /// The query behind the content currently committed, set by the screen that owns it when that
    /// screen paginates. Its presence is what tells a photo browser opened from here that it has
    /// to page for the rest of the sequence rather than being handed all of it.
    public var mediaTimelineQuery: MediaTimelineQuery?

    @Published public var selectedMode: PhotoLibraryViewMode = .all {
        didSet {
            guard selectedMode != oldValue, tracksViewModeChange else { return }
            tracker.trackViewModeChange(selectedMode)
        }
    }
    @Published public var showFilter = false
    
    var cardScrollPosition: PhotoScrollPosition?
    var photoScrollPosition: PhotoScrollPosition?
    public let contentMode: PhotoLibraryContentMode
    public let sectionHeaderType: PhotoSectionHeaderType
    public let globalHeaderType: PhotoGlobalHeaderType
    let configuration: PhotoLibraryContentConfiguration?
    
    public lazy var selection = PhotoSelection(selectLimit: configuration?.selectLimit)
    
    public lazy var filterViewModel = PhotoLibraryFilterViewModel(
        contentMode: contentMode,
        contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
    )
    
    private let tracker: any AnalyticsTracking
    
    /// The view mode events name the Media screen and are counted as its traffic, so a screen that only
    /// borrows the picker stays out of them -- taps on an album link would otherwise be indistinguishable
    /// from timeline taps. It can start reporting once the analytics repo defines events of its own.
    private var tracksViewModeChange: Bool {
        contentMode != .albumLink
    }
    
    lazy var allCollectionViewModel = PhotoLibraryModeAllCollectionViewModel(libraryViewModel: self)
    
    // MARK: - Init
    public init(
        library: PhotoLibrary,
        contentMode: PhotoLibraryContentMode = .library,
        sectionHeaderType: PhotoSectionHeaderType = .photoDate, // by default, display the photo date header
        globalHeaderType: PhotoGlobalHeaderType = .dateAndZoom, // by default, display a date and zoom control
        configuration: PhotoLibraryContentConfiguration? = nil,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.library = library
        self.contentMode = contentMode
        self.sectionHeaderType = sectionHeaderType
        self.globalHeaderType = globalHeaderType
        self.configuration = configuration
        self.tracker = tracker
        
        super.init()
    }
}

extension PhotoLibraryContentViewModel {
    var shouldShowPhotoLibraryPicker: Bool {
        configuration?.showsViewModePicker
            ?? ![.album, .albumPicker, .albumLink, .recentBucket].contains(contentMode)
    }
    
    /// Whether the picker gives its space back while selecting, rather than only fading out.
    /// The modes that do are the ones whose selection mode brings a bottom toolbar of its own.
    var shouldHidePickerWhileEditing: Bool {
        [.library, .albumLink].contains(contentMode)
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
