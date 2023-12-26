import MEGADomain
import MEGASdk
import XCTest

final class SetTypeEntityMapperTests: XCTestCase {
    func testToSetTypeEntity_mapsCorrectly() {
        [(MEGASetType.invalid, SetTypeEntity.invalid),
         (.album, .album),
         (.playlist, .playlist),
        ].forEach { sut, expectedType in
            XCTAssertEqual(sut.toSetTypeEntity(), expectedType)
        }
    }
}
