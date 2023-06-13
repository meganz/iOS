import XCTest
import Combine
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class PhotoLibraryFilterViewModelTest: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testPhotosFilterType_forImageOption_shouldReturnImage() throws {
        let sut = photoLibraryFilterViewModel().filterType(for: .images)
        XCTAssert(sut == .images)
    }
    
    func testPhotosFilterType_forVideoOption_shouldReturnVideo() throws {
        let sut = photoLibraryFilterViewModel().filterType(for: .videos)
        XCTAssert(sut == .videos)
    }
    
    func testPhotosFilterType_forAllMediaTypeOption_shouldReturnAllMediaType() throws {
        let sut = photoLibraryFilterViewModel().filterType(for: .allMedia)
        XCTAssert(sut == .allMedia)
    }
    
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
    
    func testPhotosFilterLocation_forCloudDrive_shouldReturnCloudDrive() throws {
        let sut = photoLibraryFilterViewModel().filterLocation(for: .cloudDrive)
        XCTAssert(sut == .cloudDrive)
    }
    
    func testPhotosFilterLocation_forCameraUpload_shouldReturnCameraUpload() throws {
        let sut = photoLibraryFilterViewModel().filterLocation(for: .cameraUploads)
        XCTAssert(sut == .cameraUploads)
    }
    
    func testPhotosFilterLocation_forAllLocation_shouldReturnAllLocation() throws {
        let sut = photoLibraryFilterViewModel().filterLocation(for: .allLocations)
        XCTAssert(sut == .allLocations)
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
        let useCase = MockUserAttributeUseCase()
        let sut = photoLibraryFilterViewModel(userAttributeUseCase: useCase, featureFlagProvider: MockFeatureFlagProvider(list: [.timelinePreferenceSaving: true]))
        sut.appliedMediaTypeFilter = .images
        sut.appliedFilterLocation = .cloudDrive
        
        await sut.saveFilters()
        
        XCTAssertEqual(useCase.userAttributeContainer[.contentConsumptionPreferences]?[ContentConsumptionKeysEntity.key], "\(ContentConsumptionMediaType.images.rawValue)-\(ContentConsumptionMediaLocation.cloudDrive.rawValue)")
    }
    
    func testApplySavedFilters_whenFilterScreenLoaded_shouldApplyPreviousSavedFilters() async {
        let useCase = MockUserAttributeUseCase(contentConsumption: ContentConsumptionEntity(ios: ContentConsumptionIos(timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: true))))
        let sut = photoLibraryFilterViewModel(userAttributeUseCase: useCase, featureFlagProvider: MockFeatureFlagProvider(list: [.timelinePreferenceSaving: true]))
        await sut.applySavedFilters()
        XCTAssertEqual(sut.selectedMediaType, .videos)
        XCTAssertEqual(sut.selectedLocation, .cloudDrive)
        XCTAssertTrue(sut.selectedSavePreferences)
    }
    
    func testApplySavedFilters_whenFilterScreenLoadedAndFeatureFlagIsDisabled_shouldNotApplySavedFilters() async {
        let useCase = MockUserAttributeUseCase(contentConsumption: ContentConsumptionEntity(ios: ContentConsumptionIos(timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: true))))
        let sut = photoLibraryFilterViewModel(userAttributeUseCase: useCase, featureFlagProvider: MockFeatureFlagProvider(list: [.timelinePreferenceSaving: false]))
        
        await sut.applySavedFilters()
        
        XCTAssertFalse(sut.isRememberPreferencesFeatureFlagEnabled)
        XCTAssertEqual(sut.selectedMediaType, .allMedia)
        XCTAssertEqual(sut.selectedLocation, .allLocations)
    }
    
    private func photoLibraryFilterViewModel(
        contentMode: PhotoLibraryContentMode = .library,
        userAttributeUseCase: any UserAttributeUseCaseProtocol = MockUserAttributeUseCase(),
        featureFlagProvider: FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> PhotoLibraryFilterViewModel {
        PhotoLibraryFilterViewModel(contentMode: contentMode, userAttributeUseCase: userAttributeUseCase, featureFlagProvider: featureFlagProvider)
    }
}
