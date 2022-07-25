import Combine

final class PhotoLibraryFilterViewModel: ObservableObject {
    @Published var selectedMediaType = PhotosFilterType.allMedia
    @Published var selectedLocation = PhotosFilterLocation.allLocations
    
    var lastSelectedMediaType = PhotosFilterType.allMedia
    var lastSelectedLocation = PhotosFilterLocation.allLocations
    
    func initializeLastSelection() {
        lastSelectedMediaType = selectedMediaType
        lastSelectedLocation = selectedLocation
    }
    
    func restoreLastSelection() {
        selectedMediaType = lastSelectedMediaType
        selectedLocation = lastSelectedLocation
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
    
    // MARK: - Localization
    var cancelTitle = Strings.Localizable.cancel
    var doneTitle = Strings.Localizable.done
    var filterTitle = Strings.Localizable.filter
    var chooseTypeTitle = Strings.Localizable.CameraUploads.Timeline.Filter.chooseType
    var showItemsFromTitle = Strings.Localizable.CameraUploads.Timeline.Filter.showItemsFrom
}
