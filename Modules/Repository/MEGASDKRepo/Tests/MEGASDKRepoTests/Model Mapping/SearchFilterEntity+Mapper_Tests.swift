import MEGADomain
@testable import MEGASDKRepo
import XCTest

final class SearchFilterEntity_Mapper_Tests: XCTestCase {
    
    func testToInt32_forSearchEntityFavouriteFilterOptions_shouldReturnCorrectInt32Value() {
        let options = [SearchFilterEntity.FavouriteFilterOption.disabled, .excludeFavourites, .onlyFavourites]
        
        for option in options {
            switch option {
            case .disabled:
                XCTAssertEqual(option.toInt32(), 0)
            case .onlyFavourites:
                XCTAssertEqual(option.toInt32(), 1)
            case .excludeFavourites:
                XCTAssertEqual(option.toInt32(), 2)
            }
        }
    }
}
