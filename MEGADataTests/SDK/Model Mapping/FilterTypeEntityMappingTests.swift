@testable import MEGA
import MEGADomain
import XCTest

final class FilterTypeEntityMappingTests: XCTestCase {

    func testFilterTypeToFilterEntity_onUserAlbum_shouldReturnCorrectMapping() {
        let sut: [FilterType] = [.allMedia, .images, .videos, .none]
        for type in sut {
            switch type {
            case .allMedia:
                XCTAssertEqual(type.toFilterEntity(), .allMedia)
            case .images:
                XCTAssertEqual(type.toFilterEntity(), .images)
            case .videos:
                XCTAssertEqual(type.toFilterEntity(), .videos)
            case .none:
                XCTAssertEqual(type.toFilterEntity(), .none)
            }
        }
    }
    
    func testFilterEntityToFilterType_onUserAlbum_shouldReturnCorrectMapping() {
        let sut: [FilterEntity] = [.allMedia, .images, .videos, .none]
        for type in sut {
            switch type {
            case .allMedia:
                XCTAssertEqual(type.toFilterType(), .allMedia)
            case .images:
                XCTAssertEqual(type.toFilterType(), .images)
            case .videos:
                XCTAssertEqual(type.toFilterType(), .videos)
            case .none:
                XCTAssertEqual(type.toFilterType(), .none)
            }
        }
    }
}
