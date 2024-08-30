import MEGADomain
@testable import MEGAPhotos
import XCTest

final class SearchHistoryItem_Mapper_Tests: XCTestCase {

    func testToSearchHistoryItem_map_shouldSetCorrectValues()  {
        let id = UUID()
        let query = "search"
        let date = Date()
        let sut =  SearchTextHistoryEntryEntity(id: id, query: query, searchDate: date)
        
        let result = sut.toSearchHistoryItem()
        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.query, query)
    }
}
