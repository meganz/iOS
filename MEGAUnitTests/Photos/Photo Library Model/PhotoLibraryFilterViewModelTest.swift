import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import XCTest

final class PhotoLibraryFilterViewModelTest: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testPhotosFilterOption_forImageMediaType_shouldReturnImage() throws {
        let sut = photoLibraryFilterViewModel().filterOption(for: .images)
        XCTAssert(sut == .images)
    }
    
    func testPhotosFilterOption_forVideoMediaType_shouldReturnVideo() throws {
        let sut = photoLibraryFilterViewModel().filterOption(for: .videos)
        XCTAssert(sut == .videos)
    }
    
    func testPhotosFilterOption_contentModeAlbum_shouldAlwaysReturnAllMedia() {
        let sut = photoLibraryFilterViewModel(contentMode: .album)
        XCTAssertEqual(sut.filterOption(for: .videos), .allMedia)
    }
    
    func testPhotosFilterOption_forAllMediaType_shouldReturnAllMediaOption() throws {
        let sut = photoLibraryFilterViewModel().filterOption(for: .allMedia)
        XCTAssert(sut == .allMedia)
    }
    
    func testPhotosFilterMatrixRepresentation_forTwoHundredFiftyPixel_shouldReturnTwoRows() throws {
        let sut = photoLibraryFilterViewModel().filterTypeMatrixRepresentation(forScreenWidth: 250, fontSize: 15, horizontalPadding: 15)
        XCTAssert(sut.count == 2)
    }
    
    func testPhotosFilterMatrixRepresentation_forThreeHundredFiftyPixel_shouldReturnOneRow() throws {
        let sut = photoLibraryFilterViewModel().filterTypeMatrixRepresentation(forScreenWidth: 300, fontSize: 15, horizontalPadding: 15)
        XCTAssert(sut.count == 1)
    }
    
    func testPhotosFilterOption_forAllLocation_shouldReturnAllLocation() throws {
        let sut = photoLibraryFilterViewModel().filterOption(for: .allLocations)
        XCTAssert(sut == .allLocations)
    }
    
    func testPhotosFilterOption_forCloudDrive_shouldReturnCloudDrive() throws {
        let sut = photoLibraryFilterViewModel().filterOption(for: .cloudDrive)
        XCTAssert(sut == .cloudDrive)
    }
    
    func testPhotosFilterOption_forCameraUpload_shouldReturnCameraUpload() throws {
        let sut = photoLibraryFilterViewModel().filterOption(for: .cameraUploads)
        XCTAssert(sut == .cameraUploads)
    }
    
    func testShouldShowMediaTypeFilter_initDefaultContentMode_shouldReturnTrue() {
        let sut = photoLibraryFilterViewModel()
        XCTAssertTrue(sut.shouldShowMediaTypeFilter)
    }
    
    func testShouldShowMediaTypeFilter_initAlbumContentMode_shouldReturnFalse() {
        let sut = photoLibraryFilterViewModel(contentMode: .album)
        XCTAssertFalse(sut.shouldShowMediaTypeFilter)
    }
    
    func testSetSelectedFiltersToAppliedFiltersIfRequired_onAppliedTheSameAsSelected_shouldDoNothing() {
        let sut = photoLibraryFilterViewModel()
        sut.selectedMediaType = .images
        sut.selectedLocation = .cameraUploads
        sut.selectedSavePreferences = true
        sut.appliedMediaTypeFilter = .images
        sut.appliedFilterLocation = .cameraUploads
        sut.appliedSavePreferences = true
        
        sut.setSelectedFiltersToAppliedFiltersIfRequired()
        XCTAssertEqual(sut.selectedMediaType, .images)
        XCTAssertEqual(sut.selectedLocation, .cameraUploads)
        XCTAssertTrue(sut.selectedSavePreferences)
    }
    
    func testSetSelectedFiltersToAppliedFiltersIfRequired_onAppliedDifferentFromSelected_shouldChangeSelected() {
        let sut = photoLibraryFilterViewModel()
        sut.appliedMediaTypeFilter = .images
        sut.appliedFilterLocation = .cameraUploads
        sut.appliedSavePreferences = true
        sut.setSelectedFiltersToAppliedFiltersIfRequired()
        XCTAssertEqual(sut.selectedMediaType, .images)
        XCTAssertEqual(sut.selectedLocation, .cameraUploads)
        XCTAssertTrue(sut.selectedSavePreferences)
    }
    
    func testSaveFilters_onApplyingFilters_shouldChangeTypeAndLocation() async throws {
        let useCase = MockContentConsumptionUserAttributeUseCase()
        let sut = photoLibraryFilterViewModel(contentConsumptionUserAttributeUseCase: useCase)
        sut.appliedMediaTypeFilter = .images
        sut.appliedFilterLocation = .cloudDrive
        
        await sut.saveFilters()
        
        XCTAssertEqual(useCase.timelineUserAttributeEntity, .init(mediaType: .images, location: .cloudDrive, usePreference: false))
    }
    
    func testApplySavedFilters_whenFilterScreenLoaded_shouldApplyPreviousSavedFilters() async {
        let useCase = MockContentConsumptionUserAttributeUseCase(
            timelineUserAttributeEntity: .init(mediaType: .videos, location: .cloudDrive, usePreference: true))

        let sut = photoLibraryFilterViewModel(contentConsumptionUserAttributeUseCase: useCase)
        await sut.applySavedFilters()
        XCTAssertEqual(sut.selectedMediaType, .videos)
        XCTAssertEqual(sut.selectedLocation, .cloudDrive)
        XCTAssertTrue(sut.selectedSavePreferences)
    }
    
    func testIsRememberPreferenceActive_whenFeatureFlagEnabledAndFilterIsForTimeline_shouldReturnTrue() {
        let sut = photoLibraryFilterViewModel()
        
        XCTAssertTrue(sut.isRememberPreferenceActive)
    }
    
    func testIsRememberPreferenceActive_whenFeatureFlagEnabledAndFilterIsForAlbum_shouldReturnFalse() {
        let sut = photoLibraryFilterViewModel(contentMode: .album)
        
        XCTAssertFalse(sut.isRememberPreferenceActive)
    }
    
    private func photoLibraryFilterViewModel(
        contentMode: PhotoLibraryContentMode = .library,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase()
    ) -> PhotoLibraryFilterViewModel {
        PhotoLibraryFilterViewModel(contentMode: contentMode, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase)
    }
}
