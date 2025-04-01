import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import UIKit

@MainActor
public final class PhotoLibraryFilterViewModel: ObservableObject {
    @Published var selectedMediaType = PhotosFilterType.allMedia
    @Published var selectedLocation = PhotosFilterLocation.allLocations
    @Published var selectedSavePreferences = false
    @Published var appliedMediaTypeFilter = PhotosFilterType.allMedia
    @Published public var appliedFilterLocation = PhotosFilterLocation.allLocations
    @Published var appliedSavePreferences = false
   
    private let contentMode: PhotoLibraryContentMode
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    
    var isRememberPreferenceActive: Bool {
        contentMode != .album
    }
    
    init(contentMode: PhotoLibraryContentMode = .library,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol) {
        self.contentMode = contentMode
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
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
    
    func applySavedFilters() async {
        guard isRememberPreferenceActive else { return }
        
        let timelineFilters = await contentConsumptionUserAttributeUseCase.fetchTimelineFilter()
        
        if timelineFilters.usePreference {
            selectedMediaType = timelineFilters.filterType
            selectedLocation = timelineFilters.filterLocation
            selectedSavePreferences = true
        }
        
        applyFilters()
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
        guard isRememberPreferenceActive else { return }
        
        do {
            let timeline = TimelineUserAttributeEntity(
                mediaType: appliedMediaTypeFilter.toContentConsumptionMediaType(),
                location: appliedFilterLocation.toContentConsumptionMediaLocation(),
                usePreference: appliedSavePreferences)
            
            try await contentConsumptionUserAttributeUseCase.save(timeline: timeline)
            
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

extension ContentConsumptionUserAttributeUseCaseProtocol {
    func fetchTimelineFilter() async -> (filterType: PhotosFilterType, filterLocation: PhotosFilterLocation, usePreference: Bool) {
        let ccAttributes = await fetchTimelineAttribute()
        return (
            filterType: PhotosFilterType.toFilterType(from: ccAttributes.mediaType),
            filterLocation: PhotosFilterLocation.toFilterLocation(from: ccAttributes.location),
            usePreference: ccAttributes.usePreference)
    }
}
