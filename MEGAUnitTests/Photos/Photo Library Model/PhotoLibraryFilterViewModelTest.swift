import XCTest
import Combine
@testable import MEGA
@testable import MEGADomain

class PhotosFilterOptionsTest: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
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
    
    func testPhotosFilterOption_contentModeAlbum_shouldAlwaysReturnAllMedia() {
        let sut = PhotoLibraryFilterViewModel(contentMode: .album)
        XCTAssertEqual(sut.filterOption(for: .videos), .allMedia)
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
    
    func testShouldShowMediaTypeFilter_initDefaultContentMode_shouldReturnTrue() {
        let sut = PhotoLibraryFilterViewModel()
        XCTAssertTrue(sut.shouldShowMediaTypeFilter)
    }
    
    func testShouldShowMediaTypeFilter_initAlbumContentMode_shouldReturnFalse() {
        let sut = PhotoLibraryFilterViewModel(contentMode: .album)
        XCTAssertFalse(sut.shouldShowMediaTypeFilter)
    }
    
    func testSetSelectedFiltersToAppliedFiltersIfRequired_onAppliedTheSameAsSelected_shouldDoNothing() {
        let sut = PhotoLibraryFilterViewModel()
        sut.selectedMediaType = .images
        sut.selectedLocation = .cameraUploads
        sut.appliedMediaTypeFilter = .images
        sut.appliedFilterLocation = .cameraUploads
        
        sut.setSelectedFiltersToAppliedFiltersIfRequired()
        XCTAssertEqual(sut.selectedMediaType, .images)
        XCTAssertEqual(sut.selectedLocation, .cameraUploads)
    }
    
    func testSetSelectedFiltersToAppliedFiltersIfRequired_onAppliedDifferentFromSelected_shouldChangeSelected() {
        let sut = PhotoLibraryFilterViewModel()
        sut.appliedMediaTypeFilter = .images
        sut.appliedFilterLocation = .cameraUploads
        sut.setSelectedFiltersToAppliedFiltersIfRequired()
        XCTAssertEqual(sut.selectedMediaType, .images)
        XCTAssertEqual(sut.selectedLocation, .cameraUploads)
    }
}
