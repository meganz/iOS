import MEGASdk
import XCTest

final class ContactRequestStatusEntityMapperTests: XCTestCase {
    let sut: [MEGAContactRequestStatus] = [
        .unresolved,
        .accepted,
        .denied,
        .ignored,
        .deleted,
        .reminded
    ]
    
    func testContactRequestStatusMapping() {
        for type in sut {
            let entity = type.toContactRequestStatus()
            switch type {
            case .unresolved:
                XCTAssertEqual(entity, .unresolved)
            case .accepted:
                XCTAssertEqual(entity, .accepted)
            case .denied:
                XCTAssertEqual(entity, .denied)
            case .ignored:
                XCTAssertEqual(entity, .ignored)
            case .deleted:
                XCTAssertEqual(entity, .deleted)
            case .reminded:
                XCTAssertEqual(entity, .reminded)
            default:
                XCTFail("Please map the new MEGAContactRequestStatus to ContactRequestStatusEntity")
            }
        }
    }
}
