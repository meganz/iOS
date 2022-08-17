import XCTest
@testable import MEGA
@testable import MEGADomain

class PhotosFilterOptionsTest: XCTestCase {
    func testPhotosFilterType_forImageOption_shouldReturnImage() throws {
        let sut = PhotoLibraryFilterViewModel().filterType(for: .images)
        XCTAssert(sut == .images)
    }
    
    func testPhotosFilterType_forVideoOption_shouldReturnVideo() throws {
        let sut = PhotoLibraryFilterViewModel().filterType(for: .videos)
        XCTAssert(sut == .videos)
    }
    
    func testPhotosFilterType_forAllMediaTypeOption_shouldReturnAllMediaType() throws {
        let sut = PhotoLibraryFilterViewModel().filterType(for: .allMedia)
        XCTAssert(sut == .allMedia)
    }
    
    func testPhotosFilterOption_forImageMediaType_shouldReturnImage() throws {
        let sut = PhotoLibraryFilterViewModel().filterOption(for: .images)
        XCTAssert(sut == .images)
    }
    
    func testPhotosFilterOption_forVideoMediaType_shouldReturnVideo() throws {
        let sut = PhotoLibraryFilterViewModel().filterOption(for: .videos)
        XCTAssert(sut == .videos)
    }
    
    func testPhotosFilterOption_forAllMediaType_shouldReturnAllMediaOption() throws {
        let sut = PhotoLibraryFilterViewModel().filterOption(for: .allMedia)
        XCTAssert(sut == .allMedia)
    }
    
    func testPhotosFilterMatrixRepresentation_forTwoHundredFiftyPixel_shouldReturnTwoRows() throws {
        let sut = PhotoLibraryFilterViewModel().filterTypeMatrixRepresentation(forScreenWidth: 250, fontSize: 15, horizontalPadding: 15)
        XCTAssert(sut.count == 2)
    }
    
    func testPhotosFilterMatrixRepresentation_forThreeHundredFiftyPixel_shouldReturnOneRow() throws {
        let sut = PhotoLibraryFilterViewModel().filterTypeMatrixRepresentation(forScreenWidth: 300, fontSize: 15, horizontalPadding: 15)
        XCTAssert(sut.count == 1)
    }
    
    func testPhotosFilterLocation_forCloudDrive_shouldReturnCloudDrive() throws {
        let sut = PhotoLibraryFilterViewModel().filterLocation(for: .cloudDrive)
        XCTAssert(sut == .cloudDrive)
    }
    
    func testPhotosFilterLocation_forCameraUpload_shouldReturnCameraUpload() throws {
        let sut = PhotoLibraryFilterViewModel().filterLocation(for: .cameraUploads)
        XCTAssert(sut == .cameraUploads)
    }
    
    func testPhotosFilterLocation_forAllLocation_shouldReturnAllLocation() throws {
        let sut = PhotoLibraryFilterViewModel().filterLocation(for: .allLocations)
        XCTAssert(sut == .allLocations)
    }
    
    func testPhotosFilterOption_forAllLocation_shouldReturnAllLocation() throws {
        let sut = PhotoLibraryFilterViewModel().filterOption(for: .allLocations)
        XCTAssert(sut == .allLocations)
    }
    
    func testPhotosFilterOption_forCloudDrive_shouldReturnCloudDrive() throws {
        let sut = PhotoLibraryFilterViewModel().filterOption(for: .cloudDrive)
        XCTAssert(sut == .cloudDrive)
    }
    
    func testPhotosFilterOption_forCameraUpload_shouldReturnCameraUpload() throws {
        let sut = PhotoLibraryFilterViewModel().filterOption(for: .cameraUploads)
        XCTAssert(sut == .cameraUploads)
    }
    
    //MARK: - Feature Flag
    func testShouldShowFilterMenuOnCameraUploadFeatureFlag_enabledFilterMenu_and_enabledContextMenu() {
        let testList = [FeatureFlagKey.filterMenuOnCameraUploadExplorer: true,
                        FeatureFlagKey.contextMenuOnCameraUploadExplorer: true]
        
        let provider = MockFeatureFlagProvider(list: testList)
        let sut = PhotoLibraryFilterViewModel(featureFlagProvider: provider)
        XCTAssertTrue(sut.shouldShowFilterMenuOnCameraUpload)
    }
    
    func testShouldShowFilterMenuOnCameraUploadFeatureFlag_disabledFilterMenu_and_disabledContextMenu() {
        let testList = [FeatureFlagKey.filterMenuOnCameraUploadExplorer: false,
                        FeatureFlagKey.contextMenuOnCameraUploadExplorer: false]
        
        let provider = MockFeatureFlagProvider(list: testList)
        let sut = PhotoLibraryFilterViewModel(featureFlagProvider: provider)
        XCTAssertFalse(sut.shouldShowFilterMenuOnCameraUpload)
    }
    
    func testShouldShowFilterMenuOnCameraUploadFeatureFlag_enabledFilterMenu_and_disabledContextMenu() {
        let testList = [FeatureFlagKey.filterMenuOnCameraUploadExplorer: true,
                        FeatureFlagKey.contextMenuOnCameraUploadExplorer: false]
        
        let provider = MockFeatureFlagProvider(list: testList)
        let sut = PhotoLibraryFilterViewModel(featureFlagProvider: provider)
        XCTAssertFalse(sut.shouldShowFilterMenuOnCameraUpload)
    }
}
