import XCTest
import MEGASdk
import MEGADomain

final class SetChangesEntityMapperTests: XCTestCase {
    let sut: [MEGASetChanges] = [
        .new,
        .name,
        .cover,
        .removed,
        .exported
    ]
    
    func testSetChangesMapping() {
        for type in sut {
            let entity = type.toChangesEntity()
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
                XCTFail("Please map the new MEGASetChanges to SetChangesEntity")
            }
        }
    }
}
