@testable import MEGA
import MEGADomain
import XCTest

final class SortOrderType_VideoPlaylistMapperTests: XCTestCase {
    
    // MARK: - toVideoPlaylistSortOrderEntity
    
    func testToVideoPlaylistSortOrderEntity_mapNewest_returnsCorrectValue() {
        let sortOrderType: SortOrderType = .newest
        
        let result = sortOrderType.toVideoPlaylistSortOrderEntity()
        
        XCTAssertEqual(result, .modificationDesc)
    }
    
    func testToVideoPlaylistSortOrderEntity_mapOldest_returnsCorrectValue() {
        let sortOrderType: SortOrderType = .oldest
        
        let result = sortOrderType.toVideoPlaylistSortOrderEntity()
        
        XCTAssertEqual(result, .modificationAsc)
    }
    
    func testToVideoPlaylistSortOrderEntity_mapUnsupportedValue_returnsDefaultValue() {
        let unsupportedSortOrderEntities = SortOrderType.allCases
            .filter { [SortOrderType.newest, .oldest].notContains($0) }
        
        unsupportedSortOrderEntities.enumerated().forEach { (index, sortOrderType) in
            let result = sortOrderType.toVideoPlaylistSortOrderEntity()
            
            XCTAssertEqual(result, .modificationDesc, "Failed at index: \(index) for value: \(sortOrderType)")
        }
    }
    
}
