import XCTest
import MEGASdk
import MEGADomain

final class SetElementChangesEntityMapperTests: XCTestCase {
    let sut: [MEGASetElementChanges] = [
        .changeNew,
        .name,
        .order,
        .removed
    ]
    
    func testSetElementChangesMapping() {
        for type in sut {
            let entity = type.toChangesEntity()
            switch type {
            case .changeNew:
                XCTAssertEqual(entity, .new)
            case .name:
                XCTAssertEqual(entity, .name)
            case .order:
                XCTAssertEqual(entity, .order)
            case .removed:
                XCTAssertEqual(entity, .removed)
            default:
                XCTFail("Please map the new MEGASetElementChanges to SetElementChangesEntity")
            }
        }
    }
}
