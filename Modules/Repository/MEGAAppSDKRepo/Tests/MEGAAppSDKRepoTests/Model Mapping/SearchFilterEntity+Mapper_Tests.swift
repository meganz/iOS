@testable import MEGAAppSDKRepo
import MEGADomain
import XCTest

final class SearchFilterEntity_Mapper_Tests: XCTestCase {
    
    func testtoMEGASearchFilterFavouriteOption_forSearchEntityFavouriteFilterOptions_shouldReturnCorrectMEGASearchFilterFavouriteOption() {
        let options = [SearchFilterEntity.FavouriteFilterOption.disabled, .excludeFavourites, .onlyFavourites]
        
        for option in options {
            switch option {
            case .disabled:
                XCTAssertEqual(option.toMEGASearchFilterFavouriteOption(), .disabled)
            case .onlyFavourites:
                XCTAssertEqual(option.toMEGASearchFilterFavouriteOption(), .favouritesOnly)
            case .excludeFavourites:
                XCTAssertEqual(option.toMEGASearchFilterFavouriteOption(), .nonFavouritesOnly)
            }
        }
    }
    
    func toMEGASearchFilterSensitiveOption_forSearchEntityFavouriteFilterOptions_shouldReturnCorrectMEGASearchFilterSensitiveOption() {
        let options = [SearchFilterEntity.SensitiveFilterOption.nonSensitiveOnly, .nonSensitiveOnly, .sensitiveOnly]
        
        for option in options {
            switch option {
            case .disabled:
                XCTAssertEqual(option.toMEGASearchFilterSensitiveOption(), .disabled)
            case .nonSensitiveOnly:
                XCTAssertEqual(option.toMEGASearchFilterSensitiveOption(), .nonSensitiveOnly)
            case .sensitiveOnly:
                XCTAssertEqual(option.toMEGASearchFilterSensitiveOption(), .sensitiveOnly)
            }
        }
    }
    
    func testNonRecursiveInit_shouldContainExpectedValues() {
        let parentHandle: HandleEntity = 12
        let sut: SearchFilterEntity = .nonRecursive(searchTargetNode: NodeEntity(handle: parentHandle), supportCancel: true, sortOrderType: .defaultAsc, formatType: .allDocs)
                
        let result = sut.toMEGASearchFilter()
        
        XCTAssertEqual(result.term, "")
        XCTAssertEqual(result.locationType, -1, "Expect locationType to be not set with real value when searching non-recursively")
        XCTAssertEqual(result.parentNodeHandle, parentHandle)
    }
    
    func testRecursiveInit_whenSearchinViaFolderTarget_shouldContainExpectedValues() {
        let sut: SearchFilterEntity = .recursive(searchTargetLocation: .folderTarget(.rootNode), supportCancel: true, sortOrderType: .defaultAsc, formatType: .allDocs)
                
        let result = sut.toMEGASearchFilter()
        
        XCTAssertEqual(result.term, "")
        XCTAssertEqual(result.locationType, FolderTargetEntity.rootNode.toInt32(), "Expect locationType to be set to target location")
        XCTAssertEqual(result.parentNodeHandle, 18446744073709551615, "parent node handle should be set to invalid handle when searching via locationType, INVALID_HANDLE located in megaapi.h")
    }
    
    func testRecursiveInit_whenSearchinViaNodeTarget_shouldContainExpectedValues() {
        let parentHandle: HandleEntity = 12
        let sut: SearchFilterEntity = .recursive(searchTargetLocation: .parentNode(NodeEntity(handle: parentHandle)), supportCancel: true, sortOrderType: .defaultAsc, formatType: .allDocs)
                
        let result = sut.toMEGASearchFilter()
        
        XCTAssertEqual(result.term, "")
        XCTAssertEqual(result.locationType, -1, "Expect locationType to be not set with real value when searching non-recursively")
        XCTAssertEqual(result.parentNodeHandle, parentHandle, "parent node handle should not be set when searching via locationType")
    }
}
