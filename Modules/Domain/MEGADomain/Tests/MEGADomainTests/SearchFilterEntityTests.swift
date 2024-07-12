import MEGADomain
import XCTest

final class SearchFilterEntityTests: XCTestCase {
    
    func testInitRecursiveSearchFilterEntity_withNodeLocationTarget_shouldExpectCorrectValuesForRecursiveSearch() {
        
        let sut: SearchFilterEntity = .recursive(searchTargetLocation: .folderTarget(.rootNode), supportCancel: false, sortOrderType: .creationDesc, formatType: .document)
        
        XCTAssertTrue(sut.recursive)
        XCTAssertEqual(sut.searchTargetLocation, .folderTarget(.rootNode))
    }
    
    func testInitRecursiveSearchFilterEntity_withFolderTargetLocation_shouldExpectCorrectValuesForRecursiveSearch() {
        
        let parentNode = NodeEntity(handle: 10)
        let sut: SearchFilterEntity = .recursive(searchTargetLocation: .parentNode(parentNode), supportCancel: false, sortOrderType: .creationDesc, formatType: .document)
        
        XCTAssertTrue(sut.recursive)
        XCTAssertEqual(sut.searchTargetLocation, .parentNode(parentNode))
    }
        
    func testInitNonRecursiveSearchFilterEntity_withNodeLocationTarget_shouldExpectCorrectValuesForRecursiveSearch() {
        
        let parentNode = NodeEntity(handle: 10)
        let sut: SearchFilterEntity = .nonRecursive(searchTargetNode: parentNode, supportCancel: false, sortOrderType: .creationDesc, formatType: .document)
        
        XCTAssertFalse(sut.recursive)
        XCTAssertEqual(sut.searchTargetLocation, .parentNode(parentNode))
    }
}
