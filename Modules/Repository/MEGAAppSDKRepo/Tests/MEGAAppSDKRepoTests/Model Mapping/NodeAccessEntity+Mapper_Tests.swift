@testable import MEGADomain
import XCTest

final class NodeAccessEntity_Mapper_Tests: XCTestCase {
    
    func testInitWithShareAccess() {
        XCTAssertEqual(NodeAccessTypeEntity(shareAccess: .accessRead), .read)
        XCTAssertEqual(NodeAccessTypeEntity(shareAccess: .accessReadWrite), .readWrite)
        XCTAssertEqual(NodeAccessTypeEntity(shareAccess: .accessFull), .full)
        XCTAssertEqual(NodeAccessTypeEntity(shareAccess: .accessOwner), .owner)
        XCTAssertEqual(NodeAccessTypeEntity(shareAccess: .accessUnknown), .unknown)
    }
    
    func testToShareAccessLevel() {
        XCTAssertEqual(NodeAccessTypeEntity.read.toShareAccessLevel(), .read)
        XCTAssertEqual(NodeAccessTypeEntity.readWrite.toShareAccessLevel(), .readWrite)
        XCTAssertEqual(NodeAccessTypeEntity.full.toShareAccessLevel(), .full)
        XCTAssertEqual(NodeAccessTypeEntity.owner.toShareAccessLevel(), .owner)
        XCTAssertEqual(NodeAccessTypeEntity.unknown.toShareAccessLevel(), .unknown)
    }
}
