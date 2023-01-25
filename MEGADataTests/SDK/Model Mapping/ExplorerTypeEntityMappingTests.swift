import XCTest
import MEGADomain
@testable import MEGA

final class ExplorerTypeEntityMappingTests: XCTestCase {
    
    func testMapToNodeFormatEntity() {
        let sut: [ExplorerTypeEntity] = [.audio, .video, .favourites, .document]
        for type in sut {
            switch type {
            case .audio:
                XCTAssertEqual(type.toNodeFormatEntity(), .audio)
            case .video:
                XCTAssertEqual(type.toNodeFormatEntity(), .video)
            case .favourites:
                XCTAssertEqual(type.toNodeFormatEntity(), .unknown)
            case .document:
                XCTAssertEqual(type.toNodeFormatEntity(), .document)
            }
        }
    }
}
