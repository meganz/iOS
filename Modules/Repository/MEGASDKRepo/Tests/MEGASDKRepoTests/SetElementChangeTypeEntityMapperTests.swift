import MEGADomain
import MEGASdk
import XCTest

final class SetElementChangeTypeEntityMapperTests: XCTestCase {
    let sut: [MEGASetElementChangeType] = [
        .new,
        .name,
        .order,
        .removed
    ]
    
    func testSetElementChangeTypeEntityMapping() {
        for type in sut {
            let entity = type.toChangeTypeEntity()
            switch type {
            case .new:
                XCTAssertEqual(entity, .new)
            case .name:
                XCTAssertEqual(entity, .name)
            case .order:
                XCTAssertEqual(entity, .order)
            case .removed:
                XCTAssertEqual(entity, .removed)
            default:
                XCTFail("Please map the new MEGASetElementChangeType to SetElementChangeTypeEntity")
            }
        }
    }
}
