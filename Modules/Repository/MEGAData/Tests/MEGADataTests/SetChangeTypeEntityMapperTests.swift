import MEGADomain
import MEGASdk
import XCTest

final class SetChangeTypeEntityMapperTests: XCTestCase {
    let sut: [MEGASetChangeType] = [
        .new,
        .name,
        .cover,
        .removed,
        .exported
    ]
    
    func testSetChangesMapping() {
        for type in sut {
            let entity = type.toChangeTypeEntity()
            switch type {
            case .new:
                XCTAssertEqual(entity, .new)
            case .name:
                XCTAssertEqual(entity, .name)
            case .cover:
                XCTAssertEqual(entity, .cover)
            case .removed:
                XCTAssertEqual(entity, .removed)
            case .exported:
                XCTAssertEqual(entity, .exported)
            default:
                XCTFail("Please map the new MEGASetChangeType to SetChangeTypeEntity")
            }
        }
    }
}
