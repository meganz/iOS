import Combine
import MEGADomain

final class PhotoLibraryFilterViewModel: ObservableObject {
    @Published var selectedMediaType = PhotosFilterType.allMedia
    @Published var selectedLocation = PhotosFilterLocation.allLocations
    @Published var selectedSavePreferences = false
    @Published var appliedMediaTypeFilter = PhotosFilterType.allMedia
    @Published var appliedFilterLocation = PhotosFilterLocation.allLocations
    @Published var appliedSavePreferences = false
   
    private let contentMode: PhotoLibraryContentMode
    private let userAttributeUseCase: UserAttributeUseCaseProtocol
    
    init(contentMode: PhotoLibraryContentMode = .library, userAttributeUseCase: UserAttributeUseCaseProtocol) {
        self.contentMode = contentMode
        self.userAttributeUseCase = userAttributeUseCase
    }
    
    var shouldShowMediaTypeFilter: Bool {
        contentMode != .album
    }
    
    func setSelectedFiltersToAppliedFiltersIfRequired() {
        if selectedMediaType != appliedMediaTypeFilter {
            selectedMediaType = appliedMediaTypeFilter
        }
        if selectedLocation != appliedFilterLocation {
            selectedLocation = appliedFilterLocation
        }
        if selectedSavePreferences != appliedSavePreferences {
            selectedSavePreferences = appliedSavePreferences
        }
    }
    
    @MainActor
    func applySavedFilters() async {
        do {
            if let timelineFilters = try await userAttributeUseCase.timelineFilter(), timelineFilters.usePreference {
                selectedMediaType = timelineFilters.filterType
                selectedLocation = timelineFilters.filterLocation
                selectedSavePreferences = true
            }
        } catch {
            MEGALogError("[Timeline Filter] when to load saved filters \(error.localizedDescription)")
        }
        
        applyFilters()
    }
    
    func filterType(for option: PhotosFilterOptions) -> PhotosFilterType {
        var type: PhotosFilterType
        switch option {
        case .images: type = .images
        case .videos: type = .videos
        default: type = .allMedia
        }
        return type
    }
    
    func filterOption(for type: PhotosFilterType) -> PhotosFilterOptions {
        guard shouldShowMediaTypeFilter else {
            return .allMedia
        }
        var option: PhotosFilterOptions
        switch type {
        case .images: option = .images
        case .videos: option = .videos
        default: option = .allMedia
        }
        return option
    }
    
    func filterTypeMatrixRepresentation(
        forScreenWidth screenWidth: CGFloat,
        fontSize: CGFloat,
        horizontalPadding: CGFloat
    ) -> [[PhotosFilterType]] {
        
        var filterTypeMatrix = [[PhotosFilterType]]()
        var filterTypeRow = [PhotosFilterType]()
        var rowWidth: CGFloat = 0
        let viewPaddingAdjust: CGFloat = 50
        
        PhotosFilterType.allCases.forEach { type in
            let font = UIFont.systemFont(ofSize: fontSize)
            let attributes = [NSAttributedString.Key.font: font]
            let width = (type.localization as NSString).size(withAttributes: attributes).width + horizontalPadding + horizontalPadding
            rowWidth += width
            
            if rowWidth >= screenWidth - viewPaddingAdjust {
                rowWidth = width
                filterTypeMatrix.append(filterTypeRow)
                filterTypeRow.removeAll()
            }
            filterTypeRow.append(type)
        }
        
        if filterTypeRow.isNotEmpty {
            filterTypeMatrix.append(filterTypeRow)
        }
        
        return filterTypeMatrix
    }
    
    func filterLocation(for option: PhotosFilterOptions) -> PhotosFilterLocation {
        var location: PhotosFilterLocation
        switch option {
        case .cloudDrive: location = .cloudDrive
        case .cameraUploads: location = .cameraUploads
        default: location = .allLocations
        }
        return location
    }
    
    func filterOption(for location: PhotosFilterLocation) -> PhotosFilterOptions {
        var option: PhotosFilterOptions
        switch location {
        case .cloudDrive: option = .cloudDrive
        case .cameraUploads: option = .cameraUploads
        default: option = .allLocations
        }
        return option
    }
    
    func applyFilters() {
        if selectedMediaType != appliedMediaTypeFilter {
            appliedMediaTypeFilter = selectedMediaType
        }
        if selectedLocation != appliedFilterLocation {
            appliedFilterLocation = selectedLocation
        }
        if selectedSavePreferences != appliedSavePreferences {
            appliedSavePreferences = selectedSavePreferences
        }
    }
    
    func saveFilters() async {
        do {
            let timeline = ContentConsumptionTimeline(
                mediaType: appliedMediaTypeFilter.toContentConsumptionMediaType(),
                location: appliedFilterLocation.toContentConsumptionMediaLocation(),
                usePreference: appliedSavePreferences
            )
            
            try await userAttributeUseCase.saveTimelineFilter(
                key: ContentConsumptionKeysEntity.key,
                timeline: timeline
            )
        } catch let error as JSONCodingErrorEntity {
            MEGALogError("[Timeline] Unable to save timeline filter. \(error.localizedDescription)")
        } catch {
            MEGALogError(error.localizedDescription)
        }
    }
    
    // MARK: - Localization
    var cancelTitle = Strings.Localizable.cancel
    var doneTitle = Strings.Localizable.done
    var filterTitle = Strings.Localizable.filter
    var chooseTypeTitle = Strings.Localizable.CameraUploads.Timeline.Filter.chooseType
    var showItemsFromTitle = Strings.Localizable.CameraUploads.Timeline.Filter.showItemsFrom
}
