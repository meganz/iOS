import MEGADomain
@testable import MEGASDKRepo
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
}
